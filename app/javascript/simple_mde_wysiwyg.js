function parameterize(string) {
  return string.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
}

// // Define the custom event
// var simpleMDELoadedEvent = new CustomEvent('simpleMDELoaded');

// // // Dispatch the custom event when SimpleMDE is loaded
// // function onSimpleMDELoad() {
// //   document.dispatchEvent(simpleMDELoadedEvent);
// // }

// // // Add the script load event listener
// // //var simpleMDEScript = document.querySelector('script[src="https://cdn.jsdelivr.net/simplemde/latest/simplemde.min.js"]');
// // document.addEventListener('load', onSimpleMDELoad);

// document.dispatchEvent(simpleMDELoadedEvent);

window.renderEditor = function(textarea) {
  debug('Initializing SimpleMDE for', textarea.id);
  textarea.style.display = 'block'; // Show the textarea

  // Check if SimpleMDE instance already exists and destroy it
  if (textarea.simplemdeInstance) {
    textarea.simplemdeInstance.toTextArea();
    textarea.simplemdeInstance = null;
  }

  // Initialize SimpleMDE
  var simplemde = new SimpleMDE({
    element: textarea,
    spellChecker: false,
    forceSync: true,
    toolbar: [
      "bold", "italic", "heading", "|",
      "quote", "code", "link", "image", "table", "|",
      {
        name: "subscript",
        action: function customSubscriptFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('~');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-subscript",
        title: "Insert Subscript",
      },
      {
        name: "superscript",
        action: function customSuperscriptFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('^');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-superscript",
        title: "Insert Superscript",
      },
      "|",
      {
        name: "male",
        action: function customSpecialCharFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('♂');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-mars",
        title: "Insert Male Symbol",
      },
      {
        name: "female",
        action: function customSpecialCharFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('♀');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-venus",
        title: "Insert Female Symbol",
      },
      {
        name: "plus-minus",
        action: function customSpecialCharFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('±');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-plus-minus",
        title: "Insert Plus-Minus Symbol",
      },
      {
        name: "en-dash",
        action: function customSpecialCharFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('–');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-minus",
        title: "Insert En Dash",
      },
      {
        name: "degree",
        action: function customSpecialCharFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('°');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-circle",
        title: "Insert Degree Symbol",
      },
      {
        name: "multiplication",
        action: function customSpecialCharFunction(editor) {
          var cm = editor.codemirror;
          var cursorPos = cm.getCursor();
          cm.replaceSelection('×');
          cm.setCursor(cursorPos.line, cursorPos.ch + 1);
          cm.focus();
        },
        className: "fa fa-times",
        title: "Insert Multiplication Symbol",
      },
      "preview", "side-by-side", "fullscreen"
    ],
    status: ["lines", "words", "cursor"],
    previewRender: function(plainText) {
      var md = window.markdownit()
                  .use(window.markdownitSub)
                  .use(window.markdownitSup);
      return md.render(plainText);
    }
  });

  // Store the SimpleMDE instance on the textarea element
  textarea.simplemdeInstance = simplemde;

  // Adjust the CodeMirror instance
  var cm = simplemde.codemirror;

  // After paste, scroll to the top so the beginning of the pasted content is visible
  cm.on('paste', function() {
    setTimeout(function() { cm.scrollTo(0, 0); }, 0);
  });

  debug('SimpleMDE initialized for', textarea.id, ':', simplemde);
}