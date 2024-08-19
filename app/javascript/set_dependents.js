(function() {

  // Called by some typeaheads
  window.setDependents = function(fieldId) {
    var fieldSelector, fieldValue;
    fieldSelector = `#${fieldId}`;
    fieldValue = $(fieldSelector).val();
    fieldValue = fieldValue.replace(/\s/g, '');
    if (fieldValue === '') {
      $(`.requires-${fieldId}[value=='']`).attr('disabled', 'true');
      $(`input.requires-${fieldId}`).removeClass('enabled').addClass('disabled');
      return $(`.hide-if-${fieldId}`).removeClass('hidden');
    } else {
      $(`.requires-${fieldId}`).removeAttr('disabled');
      $(`input.requires-${fieldId}`).removeClass('disabled').addClass('enabled');
      return $(`.hide-if-${fieldId}`).addClass('hidden');
    }
  };

}).call(this);






