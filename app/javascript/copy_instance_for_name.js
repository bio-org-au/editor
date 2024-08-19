(function() {
  var copyInstanceForNameFormEnter;

  $(document).on("turbo:load", function() {

    $('body').on('keydown', '#copy-instance-for-name-form', function(event) {
      return copyInstanceForNameFormEnter(event, $(this));
    });

  });

  copyInstanceForNameFormEnter = function(event, $the_button) {
    var enter_key_code, key;
    key = event.which;
    enter_key_code = 13;
    if (key === enter_key_code) {
      if ($('#confirm-or-cancel-copy-instance-link-container').hasClass('hidden')) {
        // Show the confirm/cancel buttons
        $('#confirm-or-cancel-copy-instance-link-container').removeClass('hidden');
        return false;
      } else {
        $('#create-copy-of-instance').click();
        return false;
      }
    } else {
      return true;
    }
  };

}).call(this);



