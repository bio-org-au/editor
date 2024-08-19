(function() {
  var copyNameFormEnter;

  $(document).on("turbo:load", function() {

    $('body').on('keydown', '#copy-name-form', function(event) {
      return copyNameFormEnter(event, $(this));
    });

  });

  copyNameFormEnter = function(event, $the_button) {
    var enter_key_code, key;
    key = event.which;
    enter_key_code = 13;
    if (key === enter_key_code) {
      if ($('#confirm-or-cancel-copy-name-link-container').hasClass('hidden')) {
        // Show the confirm/cancel buttons
        $('#confirm-or-cancel-copy-name-link-container').removeClass('hidden');
        return false;
      } else {
        $('#create-copy-of-name').click();
        return false;
      }
    } else {
      return true;
    }
  };

}).call(this);


