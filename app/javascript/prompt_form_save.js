let pendingHref = null;

function getFormState(form) {
  const formData = new FormData(form);
  return JSON.stringify(Array.from(formData.entries()));
}

function setInitialFormState(form) {
  form.dataset.initialState = getFormState(form);
}

function hasFormChanged(form) {
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

window.renderFormPrompt = function() {
  if (!window.enablePromptUnsavedChanges) {
    debug('Prompt unsaved changes feature is disabled.');
    return;
  }

  const forms = document.querySelectorAll("form.prompt-form-save");
  forms.forEach(form => {
    setInitialFormState(form);

    ["input", "change"].forEach(evt =>
      form.addEventListener(evt, () => {
        form.dataset.changed = hasFormChanged(form);
      })
    );

    form.addEventListener("submit", function(event) {
      if (!hasFormChanged(form)) {
        resetFormChanged(form);
        return;
      }

      event.preventDefault();
      const submitBtn = form.querySelector('[type="submit"]');
      const submitMsg = "Are you sure you want to submit? This action will save your changes.";

      const doSubmit = () => {
        resetFormChanged(form);
        form.requestSubmit ? form.requestSubmit() : form.submit();
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
    });
  });

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
window.hasUnsavedFormChanges = function() {
  return Array.from(document.querySelectorAll("form.prompt-form-save"))
    .some(form => hasFormChanged(form));
};
