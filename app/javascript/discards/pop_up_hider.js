(function() {
  var closeOpenPopups, hidePopupOrAddHider;

  window.showMessage = function(message) {
    debug('showMessage');
    $('#message-container').removeClass('hidden').addClass('visible').html(message);
    return setOneClickHider($('#message-container'));
  };

  window.setOneClickHider = function($target) {
    return $(document).one("click", function(event) {
      return hidePopupOrAddHider(event, $target);
    });
  };

  // For the "click anywhere outside popup to hide popup" feature.
  // This function gets called in the document click anywhere event.
  // The aim of that event is to hide the current popup.
  // There is a side-effect because that event fires even if the click is in the popup itself,
  // which we don't want to hide.
  // This fn defuses that case:  if click is in popup, do not hide popup.
  // There is a further complication because the hider is bound via "one", 
  // so when this function is called you will have consumed that "one" event, so 
  // you have to reset the one-off event.

  // Now, also restore title from data-title attribute.
  hidePopupOrAddHider = function(event, $target) {
    if ($(event.target).closest('.popup').length === 0) {
      return closeOpenPopups();
    } else {
      return setOneClickHider($target);
    }
  };

  closeOpenPopups = function() {
    return $('.popup').removeClass('visible').addClass('hidden');
  };


}).call(this);
