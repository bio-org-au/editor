(function() {
  var linkToRunCasClicked, linkToRunDiffClicked, linkToRunValRepClicked;

  $(document).on("turbo:load", function() {
    debug('Start of run_tree_reports.js turbo loaded');

    $('body').on('click', '#link-to-run-cas', function(event) {
      return linkToRunCasClicked(event, $(this));
    });
    $('body').on('click', '#link-to-run-diff', function(event) {
      return linkToRunDiffClicked(event, $(this));
    });
    $('body').on('click', '#link-to-run-valrep', function(event) {
      return linkToRunValRepClicked(event, $(this));
    });
  });


  linkToRunCasClicked = function(event, $the_element) {
    debug('linkToRunCasClicked');
    $('#link-to-run-cas').hide();
    $('#cas-report-is-running-indicator').removeClass('hidden');
    event = new Date();
    return $('#cas-report-is-running-indicator').html('Report started running at ' + event.toTimeString().replace(/ GMT.*/, ""));
  };

  linkToRunDiffClicked = function(event, $the_element) {
    debug('linkToRunDiffClicked');
    $('#link-to-run-diff').hide();
    $('#diff-is-running-indicator').removeClass('hidden');
    event = new Date();
    return $('#diff-is-running-indicator').html('Report started running at ' + event.toTimeString().replace(/ GMT.*/, ""));
  };

  linkToRunValRepClicked = function(event, $the_element) {
    debug('linkToRunValRepClicked');
    $('#link-to-run-valrep').hide();
    $('#val-report-is-running-indicator').removeClass('hidden');
    event = new Date();
    return $('#val-report-is-running-indicator').html('Report started running at ' + event.toTimeString().replace(/ GMT.*/, ""));
  };

}).call(this);
