(function() {
  var replaceDates, loadHtml, linkNames, linkSynonyms, linkName, loadReport;

  function replaceDates() {
    $('date').each(function (element) {
      var d = $(this).html();
      $(this).html(jQuery.format.prettyDate(d));
    });
  }
  
  window.replaceDates = replaceDates;
  
  function loadHtml(element, url, success) {
    debug("loadHtml into element");
    console.log(JSON.stringify(element));
    if (success == null) {
      success = function (data) {
        element.html(data);
        replaceDates();
      }
    }
    $.ajax({
      url: url,
      contentType: "text/html",
      beforeSend: function (jqXHR, settings) {
        jqXHR.setRequestHeader("Accept", "text/html");
      },
      complete: function (jqXHR, textStatus) {
        debug(textStatus);
      },
      success: success,
      error: function (jqXHR) {
        element.html("Data not available.")
      }
    });
  }
  
  function linkNames(selector) {
    var container = $(selector);
    container.find('data > scientific > name').each(function () {
      linkName(this)
    });
  }
  
  window.linkNames = linkNames;
  
  function linkSynonyms(selector) {
    var container = $(selector);
    container.find('nom > scientific > name').each(function () {
      linkName(this)
    });
    container.find('tax > scientific > name').each(function () {
      linkName(this)
    });
    container.find('mis > scientific > name').each(function () {
      linkName(this)
    });
    container.find('syn > scientific > name').each(function () {
      linkName(this)
    });
  }
  
  function linkName(name) {
    var name_id = $(name).data('id');
    var search_url = window.relative_url_root + '/search?query_string=id%3A+' + name_id + '+show-instances%3A&query_target=name';
    $(name).wrap('<a href="' + search_url + '" title="search" target="_blank">');
  }
  
  function loadReport(element, url) {
    element.html('<h2>Loading <i class="fa fa-refresh fa-spin"</h2>');
    loadHtml(element, url, function (data) {
      element.html(data);
      replaceDates();
      linkNames(element);
      linkSynonyms(element);
      $('.toggleNext').unbind('click').click(function () {
        toggleNext(this);
      });
      debug('loaded report.');
      $(this).find('i').removeClass('fa-spin');
    });
  }
  
  window.loadReport = loadReport;
  
  var toggleNext = function (el) {
    $(el).find('i').toggle();
    $(el).next('div').toggle(200);
  };
  
  window.toggleNext = toggleNext;
  
}).call(this);
  
  
