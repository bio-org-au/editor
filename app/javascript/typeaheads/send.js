(function() {


  function send(data, method, url, onDone) {
  $.ajax({
    method: method,
    url: url,
    data: JSON.stringify(data),
    contentType: "application/json",
    dataType: "json"
  }).done(function (respData) {
    debug(respData);
    onDone();
  }).fail(function (jqxhr, statusText) {
    if (jqxhr.status === 403) {
      debug("status 403 forbidden");
      alert("Apparently you're not allowed to do that.");
    } else if (jqxhr.responseJSON) {
      debug("Fail: " + statusText + ", " + jqxhr.responseJSON.error);
      alert(jqxhr.responseJSON.error);
    } else if (jqxhr.responseText) {
      debug("Fail: " + statusText + ", " + jqxhr.responseText);
      alert("That didn't work: " + statusText + ". " + jqxhr.responseText);
    }
  });

  window.send = send;
}


}).call(this);






