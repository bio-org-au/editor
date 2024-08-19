(function() {
  var checkSearchResultCB, clickSearchResultCB, unCheckSearchResultCB;

  clickSearchResultCB = function(event, $this) {
    debug('clickSearchResultCB');
    if ($this.hasClass('stylish-checkbox-checked')) {
      unCheckSearchResultCB(event, $this);
    } else {
      checkSearchResultCB(event, $this);
    }
    return event.preventDefault();
  };

  unCheckSearchResultCB = function(event, $this) {
    debug('unCheckSearchResultCB');
    return $this.removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
  };

  checkSearchResultCB = function(event, $this) {
    debug('checkSearchResultCB');
    return $this.removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
  };

}).call(this);

