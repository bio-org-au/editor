(function() {
  var loaderBulkShowStatsClicked;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#loader-bulk-stats-submit', function(event) {
      return loaderBulkShowStatsClicked(event, $(this));
    });
    $('body').on('click', '#loader-bulk-stats-refresh', function(event) {
      return loaderBulkShowStatsClicked(event, $(this));
    });

  });

  loaderBulkShowStatsClicked = function(event, $the_element) {
    $('#bulk-ops-stats-container').html("<br><span class='green'>Querying stats...</span><br><br><br>");
    $('#bulk-ops-stats-container').removeClass('hidden');
  };

}).call(this);


