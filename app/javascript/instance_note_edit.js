(function() {
  var cancelDeleteInstanceNote, cancelInstanceNoteEdit, deleteInstanceNote, dropdownSubmenuClick, hideDetails, hidePopupOrAddHider, 
    hideSearchResultDetailsIfMenusOpen, instanceNoteEnableOrDisableSaveButton, instanceNoteKeyIdSelectChanged;

  $(document).on("turbo:load", function() {

    $('body').on('click', 'a.instance-note-delete-link', function(event) {
      return deleteInstanceNote(event, $(this));
    });
    $('body').on('click', 'a.instance-note-cancel-delete-link', function(event) {
      return cancelDeleteInstanceNote(event, $(this));
    });
    $('body').on('click', 'a.instance-note-cancel-edit-link', function(event) {
      return cancelInstanceNoteEdit(event, $(this));
    });
    $('body').on('change', '.instance-note-key-id-select', function(event) {
      return instanceNoteKeyIdSelectChanged(event, $(this));
    });
  });

  instanceNoteKeyIdSelectChanged = function(event, $element) {
    var instanceNoteId;
    debug('instanceNoteKeyIdSelectChanged');
    instanceNoteId = $element.attr('data-instance-note-id');
    instanceNoteEnableOrDisableSaveButton(event, $element, instanceNoteId);
    return event.preventDefault();
  };

  // Disable save button if either mandatory field is empty.
  instanceNoteEnableOrDisableSaveButton = function(event, $element, instanceNoteId) {
    debug('instanceNoteEnableOrDisableSaveButton');
    if ($(`#instance-note-key-id-select-${instanceNoteId}`).val().length === 0 || $(`#instance-note-value-text-area-${instanceNoteId}`).val().length === 0) {
      $(`#instance-note-save-btn-${instanceNoteId}`).addClass('disabled');
    } else {
      $(`#instance-note-save-btn-${instanceNoteId}`).removeClass('disabled');
    }
    return event.preventDefault();
  };

  
  // Cancel editing for a specific instance note.
  cancelInstanceNoteEdit = function(event, $element) {
    var instanceNoteId;
    debug('cancelInstanceNoteEdit');
    instanceNoteId = $element.attr('data-instance-note-id');
    // Cancel the delete confirmation dialog if in progress.
    $(`a#instance-note-cancel-delete-link-${instanceNoteId}`).not('.hidden').click();
    // Throw the form away.
    $(`div#instance-note-edit-form-container-${$element.attr('data-instance-note-id')}`).text('');
    // Show the edit link.
    $(`#instance-note-edit-link-${instanceNoteId}`).removeClass('hidden');
    // Hide the cancel edit link.
    $(`#instance-note-cancel-edit-link-${instanceNoteId}`).addClass('hidden');
    // Hide the delete link.
    $(`#instance-note-delete-link-${instanceNoteId}`).addClass('hidden');
    // Enable the (hidden) delete link.
    $(`#instance-note-delete-link-${instanceNoteId}`).removeClass('disabled');
    // This doesn't this work: a delay occurs as a request is made to the server!
    //event.preventDefault()
    return false;
  };

  cancelDeleteInstanceNote = function(event, $element) {
    var instanceNoteId;
    debug('cancelDeleteInstanceNote');
    instanceNoteId = $element.attr('data-instance-note-id');
    debug(instanceNoteId);
    $(`#instance-note-delete-link-${instanceNoteId}`).removeClass('disabled');
    $element.parent().addClass('hidden');
    debug($element.parent().parent().children('span.delete').children('a.disabled').length);
    $element.parent().parent().children('span.delete').children('a.disabled').removeClass('disabled');
    $(`#${$element.attr('data-confirm-btn-id')}`).addClass('hidden');
    return event.preventDefault();
  };

  deleteInstanceNote = function(event, $element) {
    var instanceNoteId;
    debug('deleteInstanceNote');
    instanceNoteId = $element.attr('data-instance-note-id');
    $(`#instance-note-delete-link-${instanceNoteId}`).addClass('disabled');
    $(`#confirm-or-cancel-delete-instance-note-${instanceNoteId}`).removeClass('hidden');
    return event.preventDefault();
  };

}).call(this);

