(function() {
  var showResourceEditForm, hideResourceEditForm, saveResourceEdit;

  $(document).on("turbo:load", function() {

    // Show edit form when clicking Edit button
    $('body').on('click', 'a.show-resource-edit-form', function(event) {
      return showResourceEditForm(event, $(this));
    });

    // Cancel edit form
    $('body').on('click', 'a.cancel-resource-edit-btn', function(event) {
      return hideResourceEditForm(event, $(this));
    });

    // Save resource edit
    $('body').on('click', 'a.save-resource-btn', function(event) {
      return saveResourceEdit(event, $(this));
    });

  });

  showResourceEditForm = function(event, $element) {
    debug('showResourceEditForm');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // Hide the display view
    $(`#${displayId}`).addClass('hidden');

    // Show the edit form
    $(`#${targetId}`).removeClass('hidden');

    $('.message-container').html('');
    return event.preventDefault();
  };

  hideResourceEditForm = function(event, $element) {
    debug('hideResourceEditForm');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // Hide the edit form
    $(`#${targetId}`).addClass('hidden');

    // Show the display view
    $(`#${displayId}`).removeClass('hidden');

    $('.message-container').html('');
    $('.error-container').html('');
    return event.preventDefault();
  };

  saveResourceEdit = function(event, $element) {
    debug('saveResourceEdit');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // TODO: Add AJAX call to save the resource data here
    // For now, just hide the form and show the display

    // Hide the edit form
    $(`#${targetId}`).addClass('hidden');

    // Show the display view
    $(`#${displayId}`).removeClass('hidden');

    // Show success message
    $('#search-result-details-info-message-container').html('Resource updated successfully');

    return event.preventDefault();
  };

}).call(this);
