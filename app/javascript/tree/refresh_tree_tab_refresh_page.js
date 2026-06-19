(function() {
  window.refreshTreeTab = function(event) {
    $('#instance-classification-tab').click();
    event.preventDefault();
    return false;
  };

  window.refreshPage = function() {
    location.reload();
  };

}).call(this);
