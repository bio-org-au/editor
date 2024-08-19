(function() {

  $(document).on("turbo:load", function() {

    $('body').on('click', '.cancel-new-record-link', function(event) {
      return cancelNewRecord(event, $(this));
    });

  });

  window.cancelNewRecord = function(event, $element) {
    $('#search-result-details').html('');
    $(`#${$element.attr('data-element-id')}`).remove();
    return false;
  };

}).call(this);











