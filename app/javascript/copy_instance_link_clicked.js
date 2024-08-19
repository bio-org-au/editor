(function() {
  var copyInstanceLinkClicked;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#copy-instance-link', function(event) {
      return copyInstanceLinkClicked(event, $(this));
    });

  });

  copyInstanceLinkClicked = function(event, $the_element) {
    debug('copyInstanceLinkClicked');
    $('#confirm-or-cancel-copy-instance-link-container').removeClass('hidden');
    return event.preventDefault();
  };

}).call(this);





