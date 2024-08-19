(function() {
  var createCopyOfNameClick;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#create-copy-of-name', function(event) {
      return createCopyOfNameClick(event, $(this));
    });
  });

  createCopyOfNameClick = function(event, $the_element) {
    debug('createCopyOfNameClick');
    $('#copy-name-error-message-container').html('');
    $('#copy-name-error-message-container').addClass('hidden');
    $('#copy-name-info-message-container').html('');
    $('#copy-name-info-message-container').addClass('hidden');
    return true;
  };

}).call(this);




