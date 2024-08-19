// Moved to a discard file because no string 'tree-row' found in app, so 
// apparently no element has this class - hence event will never occur.
//

(function() {
  var treeRowClicked, treeRowClicked2, changeTreeFocus, loadTreeDetails;

  $(document).on("turbo:load", function() {
    $('body').on('click', '.tree-row div.head', function(event) {
      return treeRowClicked(event, $(this));
    });
  });
  treeRowClicked = function(event, $this) {
    debug('treeRowClicked');
    if (!$this.hasClass('showing-details')) {
      changeTreeFocus(event, $this);
      $('#search-results.nothing-selected').removeClass('nothing-selected').addClass('something-selected');
    }
    return event.preventDefault();
  };

  treeRowClicked2 = function(event, $this, data) {
    return debug('treeRowClicked2');
  };

  changeTreeFocus = function(event, inFocus) {
    debug(`changeTreeFocus: id: ${inFocus.attr('id')}; event target: ${event.target}`);
    $('.showing-details').removeClass('showing-details');
    inFocus.addClass('showing-details');
    loadTreeDetails(event, inFocus);
    return event.preventDefault();
  };

  window.loadTreeDetails = function(event, inFocus, tabWasClicked = false) {
    var instance_id, record_type, tabIndex, url;
    debug('window.loadTreeDetails');
    $('#search-result-details').show();
    $('#search-result-details').removeClass('hidden');
    record_type = 'instance'; //$('tr.showing-details').attr('data-record-type')
    tabIndex = 1; //$('.search-result.showing-details a[tabindex]').attr('tabindex')
    debug(`tabIndex: ${tabIndex}`);
    url = `${inFocus.attr('data-edit-url').replace(/0/, '')}${inFocus.attr('data-instance-id')}?tab=${currentActiveTab(record_type)}&tabIndex=${tabIndex}&rowType=${inFocus.attr('data-row-type')}`;
    debug(`url: ${url}`);
    $('#search-result-details').load(url, function() {
      debug("after get");
      recordCurrentActiveTab(record_type);
      if (tabWasClicked) {
        debug('tab clicked loadTreeDetails');
        if ($('.give-me-focus')) {
          debug('give-me-focus ing');
          return $('.give-me-focus').focus();
        } else {
          debug('just focus the tab');
          return $('li.active a.tab').focus();
        }
      }
    });
    return event.preventDefault();
  };

}).call(this);
