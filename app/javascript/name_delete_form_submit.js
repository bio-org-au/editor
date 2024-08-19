(function() {
  var nameDeleteFormSubmit;

  $(document).on("turbo:load", function() {
  
    $('body').on('submit', '#name-delete-form', function(event) {
      return nameDeleteFormSubmit(event, $(this));
    });
    
  });

  nameDeleteFormSubmit = function(event, $element) {
    $('#confirm-delete-name-button').attr('disabled', 'true');
    $('#cancel-delete-link').attr('disabled', 'true');
    $('#name-delete-tab').attr('disabled', 'true').addClass('disabled');
    $('#search-result-details-error-message-container').html('');
    $('#name-delete-spinner').removeClass('hidden');
    return true;
  };

}).call(this);



