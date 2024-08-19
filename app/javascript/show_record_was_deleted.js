(function() {

  window.showRecordWasDeleted = function(recordId, recordType) {
    $("#search-result-details").addClass('hidden');
    $('#search-result-details').html('');
    return $(`#search-result-${recordId}`).addClass('hidden');
  };

}).call(this);







