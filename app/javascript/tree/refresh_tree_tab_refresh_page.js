(function() {
  var refreshTreeTab, refreshPage;

  function refreshTreeTab(event) {
    $('#instance-classification-tab').click();
    event.preventDefault();
    return false;
  }

  function refreshPage() {
  location.reload();
  }

}).call(this);
