(function() {
  var makeTargetInvisible, makeTargetVisible, toggleVisibleHidden;

  makeTargetVisible = function($target) {
    debug(`makeTargetVisible: ${$target.attr('id')}`);
    return $target.removeClass('hidden').addClass('visible');
  };

  makeTargetInvisible = function($target) {
    return $target.removeClass('visible').addClass('hidden');
  };

  toggleVisibleHidden = function($target) {
    if ($target.hasClass('hidden')) {
      return makeTargetVisible($target);
    } else {
      return makeTargetInvisible($target);
    }
  };

}).call(this);


