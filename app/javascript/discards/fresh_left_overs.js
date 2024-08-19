(function() {
  var reviewResultKeyNavigation, searchResultsCheckedCount;

  $(document).on("turbo:load", function() {
    debug('Start of fresh-left-overs.js turbo loaded');
    debug('jQuery version: ' + $().jquery);

    $('tr.review-result').keydown(function(event) {
      return reviewResultKeyNavigation(event, $(this));
    });

    if (window.location.hash) {
      $('a#' + window.location.hash).click();
    }
    $('body').on('change', 'select#query-on', function(event) {
      return queryonSelectChanged(event, $(this));
    });
    
    $('body').on('click', '#instance-reference-typeahead', function(event) {
      return $(this).select();
    });
    debug("on load - search-target-button-text: " + $('#search-target-button-text').text().trim());
    if (typeof showOrHideCultivarCommonCbox === 'function') {
      window.showOrHideCultivarCommonCbox($('#search-target-button-text').text().trim());
    }
  });

  window.showInstanceWasCreated = function(recordId, fromRecordType, fromRecordId) {
    return debug(`showInstanceWasCreated: recordId: ${recordId}; fromRecordType: ${fromRecordType}; fromRecordId: ${fromRecordId}`);
  };

}).call(this);








