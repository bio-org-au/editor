(function() {
  var positionOnTheRight;

  positionOnTheRight = function(clickPosition, $target, offset) {
    $target.css('left', clickPosition.left + offset);
    return $target.css('top', clickPosition.top);
  };

}).call(this);





