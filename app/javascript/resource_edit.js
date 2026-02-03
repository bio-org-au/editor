(function() {
  var showResourceEditForm, hideResourceEditForm;
  var showAddResourceForm, hideAddResourceForm, saveNewResource;
  var clearMessages;

  $(document).on("turbo:load", function() {

    // Show edit form when clicking Edit button
    $('body').on('click', 'a.show-resource-edit-form', function(event) {
      return showResourceEditForm(event, $(this));
    });

    // Cancel edit form
    $('body').on('click', 'a.cancel-resource-edit-btn', function(event) {
      return hideResourceEditForm(event, $(this));
    });

    // Show add resource form when clicking Add Resource button
    $('body').on('click', '#add-resource-button', function(event) {
      return showAddResourceForm(event, $(this));
    });

    // Cancel adding new resource
    $('body').on('click', '#cancel-new-resource-btn', function(event) {
      return hideAddResourceForm(event);
    });

    // Save new resource
    $('body').on('click', '#save-new-resource-btn', function(event) {
      return saveNewResource(event);
    });

  });

  clearMessages = function() {
    $('.message-container').html('');
    $('.error-container').html('');
  };

  showResourceEditForm = function(event, $element) {
    debug('showResourceEditForm');
    const targetId = $element.data('target-id');
    const displayId = $element.data('display-id');

    // Hide the display view
    $(`#${displayId}`).addClass('hidden');

    // Show the edit form
    $(`#${targetId}`).removeClass('hidden');

    clearMessages();
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

    clearMessages();
    return event.preventDefault();
  };

  showAddResourceForm = function(event, $element) {
    debug('showAddResourceForm');

    const selectedResourceId = $('#resource-type-select').val();
    const selectedResourceText = $('#resource-type-select option:selected').text();

    // Validate selection
    if (!selectedResourceId) {
      $('#search-result-details-error-message-container').html('Please select a resource type first');
      return event.preventDefault();
    }

    $('#new-resource-host').val(selectedResourceText);
    $('#new-resource-host').data('resource-host-id', selectedResourceId);

    $('#resource-host-id-hidden').val(selectedResourceId);

    const resolvingUrl = $('#resource-type-select option:selected').data('resolving-url') || '';
    $('#new-resource-url').val(resolvingUrl);

    $('#new-resource-value').val('');
    $('#new-resource-note').val('');

    $('.add-resource-form').addClass('hidden');

    $('#add-resource-form-container').removeClass('hidden');

    $('#new-resource-value').focus();

    clearMessages();

    return event.preventDefault();
  };

  hideAddResourceForm = function(event) {
    debug('hideAddResourceForm');

    $('#add-resource-form-container').addClass('hidden');

    $('.add-resource-form').removeClass('hidden');

    $('#new-resource-host').val('');
    $('#new-resource-value').val('');
    $('#new-resource-note').val('');
    $('#new-resource-url').val('');

    clearMessages();

    return event.preventDefault();
  };

  saveNewResource = function(event) {
    debug('saveNewResource');

    const resourceValue = $('#new-resource-value').val();
    if (!resourceValue) {
      $('#search-result-details-error-message-container').html('Resource value is required');
      return event.preventDefault();
    }

    // Allow form to submit via Rails remote form handling
    return true;
  };

}).call(this);
