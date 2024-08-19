(function() {
  var loadCheckSynonymyReport;


  function loadCheckSynonymyReport(element, url) {
    element.html('<h2>Loading <i class="fa fa-refresh fa-spin"</h2>');
    $('#update_checked_synonymy').addClass('hidden');
    loadHtml(element, url, function (data) {
      debug('start of anon function');
      element.html(data);
      if (element.find('input').length) {
        replaceDates();
        linkNames(element);
        linkSynonyms(element);
        $('.toggleNext').unbind('click').click(function () {
          toggleNext(this);
        });
        $('#update_checked_synonymy').removeClass('hidden');
      }
      debug('loaded synonymy report.');
    });
  }
  
  window.loadCheckSynonymyReport = loadCheckSynonymyReport;

}).call(this);
