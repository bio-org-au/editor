(function() {
  var confirmNameRefreshChildrenButtonClick;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#confirm-name-refresh-children-button', function(event) {
      return confirmNameRefreshChildrenButtonClick(event, $(this));
    });

  });

  confirmNameRefreshChildrenButtonClick = function(event, $the_button) {
    debug('confirmNameRefreshChildrenButtonClick');
    $the_button.attr('disabled', 'true');
    $('#cancel-refresh-children-link').attr('disabled', 'true');
    $('#name-refresh-tab').attr('disabled', 'true');
    $('#search-result-details-error-message-container').html('');
    return $('#refresh-children-spinner').removeClass('hidden');
  };

}).call(this);


