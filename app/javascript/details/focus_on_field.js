
(function() {
  var focusOnField;

  focusOnField = function(field_id) {
    let field = document.getElementById(field_id);
      field?.focus()
  };
  window.focusOnField = focusOnField;

}).call(this);
