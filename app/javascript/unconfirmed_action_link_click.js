(function() {
  var unconfirmedActionLinkClick;

  $(document).on("turbo:load", function() {
    
    $('body').on('click', 'a.unconfirmed-delete-link', function(event) {
      return unconfirmedActionLinkClick(event, $(this));
    });
    $('body').on('click', 'a.unconfirmed-action-link', function(event) {
      return unconfirmedActionLinkClick(event, $(this));
    });

  });

  unconfirmedActionLinkClick = function(event, $element) {
    debug('unconfirmedActionLinkClick');
    $(`#${$element.attr('data-show-this-id')}`).removeClass('hidden');
    $element.addClass('disabled');
    $('.message-container').html('');
    return event.preventDefault();
  };

}).call(this);



