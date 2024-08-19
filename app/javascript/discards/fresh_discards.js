// functions pulled out of fresh_left_overs because I think they're not used anywhere
// i.e. can't find evidence in static code of their use
(function() {
  var showFieldIsNotYetSaved, searchResultRecordType;

  showFieldIsNotYetSaved = function($element) {
    $element.addClass('changed').addClass('not-saved');
  };

  searchResultRecordType = function() {
    debug(searchResultRecordType());
    debug($('#search-results tr.search-result .stylish-checkbox-checked').length);
    return $('#search-results tr.search-result .stylish-checkbox-checked').closest('tr').attr('data-record-type');
  };

  // from main.js
  function loadAleredSynonymyReport(element, url) {
  element.html('<h2>Loading <i class="fa fa-refresh fa-spin"</h2>');
  $('#update_selected_synonymy').addClass('hidden');
  loadHtml(element, url, function (data) {
    element.html(data);
    if (element.find('input').length) {
      replaceDates();
      linkNames(element);
      linkSynonyms(element);
      $('.toggleNext').unbind('click').click(function () {
        toggleNext(this);
      });
      $('#update_selected_synonymy').removeClass('hidden');
    }
    debug('loaded synonymy report.');
  });
  }

}).call(this);
