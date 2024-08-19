(function() {
  var cancelLinkClick;

  $(document).on("turbo:load", function() {

    $('body').on('click', 'a.cancel-link', function(event) {
      return cancelLinkClick(event, $(this));
    });
    $('body').on('click', 'a.cancel-action-link', function(event) {
      return cancelLinkClick(event, $(this));
    });
    
  });

  cancelLinkClick = function(event, $element) {
    debug('cancelLinkClick');
    debug(`data-hide-this-id: ${$element.attr('data-hide-this-id')}`);
    debug(`data-enable-this-id: ${$element.attr('data-enable-this-id')}`);
    $(`#${$element.attr('data-hide-this-id')}`).addClass('hidden');
    $(`#${$element.attr('data-enable-this-id')}`).removeClass('disabled');
    $(`.${$element.attr('data-empty-this-class')}`).html('');
    $('.message-container').html('');
    $('.error-container').html('');
    return event.preventDefault();
  };

}).call(this);




