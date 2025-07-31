let pendingHref = null;
let noUnloadCheck = false;

const observer = new MutationObserver(mutations => {
  let nodeClass = "form";
  if (!window.enableSiteWidePromptUnsavedChanges) { nodeClass = "form.prompt-form-save"; }
  mutations.forEach(mutation => {
    mutation.addedNodes.forEach(node => {
      if (node.nodeType === 1 && node.matches && node.matches(nodeClass)) {
        setInitialFormState(node);
      }
      // If forms are nested deeper:
      if (node.nodeType === 1 && node.querySelectorAll) {
        node.querySelectorAll(nodeClass).forEach(setInitialFormState);
      }
    });
  });
});

if (window.enablePromptUnsavedChanges) {
  observer.observe(document.body, { childList: true, subtree: true });
}

// --- Form State Helpers ---
function getFormState(form) {
  const formData = new FormData(form);
  return JSON.stringify(Array.from(formData.entries()));
}

function setInitialFormState(form) {
  form.dataset.initialState = getFormState(form);
}

function hasFormChanged(form) {
  if (getFormState(form) !== form.dataset.initialState) {
    console.log("has form changed: ", getFormState(form))
    console.log("has form initial: ", form.dataset.initialState)
  }
  return getFormState(form) !== form.dataset.initialState;
}

function resetFormChanged(form) {
  form.dataset.changed = "false";
  setInitialFormState(form);
}

function showUnsavedChangesModal(onContinue, onBack, message) {
  const modal = document.getElementById('unsaved-changes-modal');
  const continueBtn = document.getElementById('unsaved-continue');
  const backBtn = document.getElementById('unsaved-back');
  const messageElem = document.getElementById('unsaved-changes-message');
  const defaultMsg = "You have unsaved changes. Continue?";

  if (modal) modal.style.display = 'flex';
  if (messageElem) messageElem.textContent = message || defaultMsg;

  if (continueBtn) {
    continueBtn.onclick = () => {
      modal.style.display = 'none';
      if (messageElem) messageElem.textContent = defaultMsg;
      if (typeof onContinue === "function") onContinue();
    };
  }
  if (backBtn) {
    backBtn.onclick = () => {
      modal.style.display = 'none';
      if (messageElem) messageElem.textContent = defaultMsg;
      if (typeof onBack === "function") onBack();
    };
  }
}
function getPromptableForms() {
  let forms;
  if (window.enableSiteWidePromptUnsavedChanges && window.enablePromptUnsavedChanges) {
    forms = Array.from(document.querySelectorAll("form"));
  } else {
    forms = Array.from(document.querySelectorAll("form.prompt-form-save"));
  }
  return forms.filter(form => form.id !== "search-form" && !form.querySelector('.auto-submit-on-change'));

}
// --- Global Unsaved Changes Check ---
window.hasUnsavedFormChanges = function() {
  const forms = getPromptableForms();
  return Array.from(forms).some(form => hasFormChanged(form));
};

window.renderFormPrompt = function() {
  // Handle auto-submit dropdowns
  document.querySelectorAll('select.auto-submit-on-change').forEach(select => {
    select.dataset.prevValue = select.value;

    select.addEventListener('change', function(event) {
      const form = select.form;
      if (window.enablePromptUnsavedChanges && window.hasUnsavedFormChanges && window.hasUnsavedFormChanges()) {
        const doSubmit = () => form.requestSubmit();
        const doCancel = () => { select.value = select.dataset.prevValue; };
        event.preventDefault();
        if (window.showUnsavedChangesModal) {
          window.showUnsavedChangesModal(doSubmit, doCancel);
        }
        return false;
      }
      // No unsaved changes, submit as normal
      form.requestSubmit ? form.requestSubmit() : form.submit();
    });

    // Update prevValue on successful submit
    if (select.form) {
      select.form.addEventListener("submit", function() {
        select.dataset.prevValue = select.value;
      });
    }
  });

  if (!window.enablePromptUnsavedChanges) {
    if (typeof debug === "function") debug('Prompt unsaved changes feature is disabled.');
    return;
  }

  // Track changes on all prompt-form-save forms
  const forms = getPromptableForms();
  // Use a WeakMap to track skipNextSubmit per form
  const skipNextSubmitMap = new WeakMap();
  forms.forEach(form => {
    setInitialFormState(form);

    ["input", "change"].forEach(evt =>
      form.addEventListener(evt, () => {
        form.dataset.changed = hasFormChanged(form);
      })
    );

    // Remove any previous handler to avoid double-binding
    if (form._promptFormSaveHandler) {
      form.removeEventListener("submit", form._promptFormSaveHandler);
    }

    const handler = function(event) {
      if (skipNextSubmitMap.get(form)) {
        skipNextSubmitMap.set(form, false);
        return; // Allow the submit to go through
      }

      const alwaysPrompt = form.classList.contains('always-prompt-before-action');
      if (!alwaysPrompt && !hasFormChanged(form)) {
        resetFormChanged(form);
        return;
      }

      event.preventDefault();
      const submitBtn = form.querySelector('[type="submit"]');
      const submitMsg = "Are you sure you want to submit? This action will save your changes.";

      const doSubmit = () => {
        skipNextSubmitMap.set(form, true);
        form.requestSubmit ? form.requestSubmit(submitBtn) : form.submit();
        if (modal) modal.style.display = 'none';
        resetFormChanged(form)
      };
      const onCancel = () => {
        if (submitBtn) submitBtn.disabled = false;
      };

      if (window.showUnsavedChangesModal) {
        window.showUnsavedChangesModal(doSubmit, onCancel, submitMsg);
      } else if (confirm(submitMsg)) {
        doSubmit();
      } else {
        onCancel();
      }
    };

    form.addEventListener("submit", handler);
    form._promptFormSaveHandler = handler;
  });

  // Tab navigation with unsaved changes prompt
  const modal = document.getElementById('unsaved-changes-modal');
  document.querySelectorAll('a.tab').forEach(tab => {
    tab.addEventListener('click', event => {
      if (window.hasUnsavedFormChanges && window.hasUnsavedFormChanges()) {
        event.preventDefault();
        pendingHref = tab.getAttribute('href');
        if (modal) modal.style.display = 'flex';
      }
    });
  });

  // Modal continue/back for tab navigation
  const continueBtn = document.getElementById('unsaved-continue');
  const backBtn = document.getElementById('unsaved-back');
  if (continueBtn) {
    continueBtn.onclick = () => {
      if (modal) modal.style.display = 'none';
      if (pendingHref) {
        window.location.href = pendingHref;
        pendingHref = null;
      }
    };
  }
  if (backBtn) {
    backBtn.onclick = () => {
      if (modal) modal.style.display = 'none';
      pendingHref = null;
    };
  }
};

window.showUnsavedChangesModal = showUnsavedChangesModal;

$(window).on('beforeunload', function (e) {
  if (window.enablePromptUnsavedChanges && !noUnloadCheck && window.hasUnsavedFormChanges && window.hasUnsavedFormChanges()) {
    e.preventDefault();
    return false;
  }
});

$('body').on('click', 'a', function(event) {
  const href = $(this).attr('href');
  if (!href || href.startsWith('#') || $(this).hasClass('no-unsaved-check')) return;

  if (window.enablePromptUnsavedChanges && window.hasUnsavedFormChanges && window.hasUnsavedFormChanges()) {
    event.preventDefault();
    const proceed = () => {
      noUnloadCheck = true;
      window.location.href = href;
    };
    if (window.showUnsavedChangesModal) {
      window.showUnsavedChangesModal(proceed);
    } else if (confirm("You have unsaved changes. Continue?")) {
      proceed();
    }
    return false;
  }
});
