(function() {
  var changeFocus, clickOnFocus, currentActiveTab, promptFormUnsavedChanges, optionalFocusOnPageLoad, recordCurrentActiveTab, searchResultFocus, unconfirmedActionLinkClick;


  $(document).on("load", function() {
    debug('document load, search_result_focus.js');
  });
  $(document).on("turbolinks:load", function() {
    debug('turbolinks:load, search_result_focus.js');
  });
  $(document).on("turbo:load", function() {
    debug('turbo:load, search_result_focus.js');
  });

  $(window).on('load', function(){
    debug('jquery window loaded, search_result_focus.js');
  });

  $(document).on("turbo:load", function() {
    debug('Start of search_result_focus.js turbo loaded');

    $('tr.search-result td.takes-focus').click(function(event) {
      return searchResultFocus(event, $(this).parent('tr'));
    });

    $('body').on('focus', 'tr.review-result td.takes-focus', function(event) {
      return searchResultFocus(event, $(this).parent('tr'));
    });

    // When tabbing to search-result record, need to click to trigger retrieval of details.
    $('a.show-details-link[tabindex]').focus(function(event) {
      const proceed = () => {
        clickOnFocus(event, $(this));
      };

      if(window.enablePromptUnsavedChanges == true) {
        promptFormUnsavedChanges(event, proceed);
      } else {
        return proceed();
      }
    });

    $('body').on('click', '.edit-details-tab', function(event) {
      const proceed = () => {
        loadDetails(event, $(this), true);
      };

      if(window.enablePromptUnsavedChanges == true) {
        promptFormUnsavedChanges(event, proceed);
        return false;
      } else {
        return proceed();
      }
    });

    optionalFocusOnPageLoad();
    return debug('End of search_result_focus.js document ready.');
  });

  promptFormUnsavedChanges = function(event, proceedCallback) {
    if (window.enablePromptUnsavedChanges && window.hasUnsavedFormChanges && window.hasUnsavedFormChanges()) {
      event.preventDefault();
      if (window.showUnsavedChangesModal) {
        window.showUnsavedChangesModal(proceedCallback);
      } else if (confirm("You have unsaved changes. Continue?")) {
        if(proceedCallback) proceedCallback();
      }
      return false;
    }
    if(proceedCallback) proceedCallback();
  };

  optionalFocusOnPageLoad = function() {
    try {
    debug('optionalFocusOnPageLoad start');
    var focusId, focusSelector;
    focusId = $('#focus_id').val();
    if (!focusId) {
      return $('table.search-results tr td.takes-focus a.show-details-link[tabindex]').first().click();
    } else {
      focusSelector = `#${focusId.replace(/::.*-/g, '-')}`;

      if ($(focusSelector).length === 1) {
        return $(focusSelector).click();
      } else {
        return $('table.search-results tr td.takes-focus a.show-details-link[tabindex]').first().click();
      }
    }
  }
    catch(err) {
      debug('optionalFocusOnPageLoad Error: ' + err.toString());
      return;
    }
  };

  clickOnFocus = function(event, $element) {
    debug(`clickOnFocus: id: ${$element.attr('id')}; event target: ${event.target}`);
    return $element.click();
  };

  window.loadDetails = function(event, inFocus, tabWasClicked = false) {
    debug('window.loadDetails starting');
    return loadStandardDetails(event, inFocus, tabWasClicked);
  };

  window.loadStandardDetails = function(event, inFocus, tabWasClicked = false) {
    var err, instance_type, record_type, row_type, tabIndex, url;
    debug('window.loadStandardDetails starting');
    $('#search-result-details').show();
    $('#search-result-details').removeClass('hidden');
    record_type = $('tr.showing-details').attr('data-record-type');
    debug(`record_type: ${record_type}`);
    instance_type = $('tr.showing-details').attr('data-instance-type');
    debug(`instance_type: ${instance_type}`);
    row_type = $('tr.showing-details').attr('data-row-type');
    debug(`row_type: ${row_type}`);
    tabIndex = $('.search-result.showing-details a[tabindex]').attr('tabindex');
    try {
      url = inFocus.attr('data-tab-url').replace(/active_tab_goes_here/, currentActiveTab(record_type));
    } catch (error1) {
      err = error1;
      debug(err);
    }
    debug(`starting url: ${url}`);
    const paramJoin = url.includes('?') ? '&' : '?';
    url = url + `${paramJoin}format=js&tabIndex=${tabIndex}`;
    if (row_type != null) {
      url = url + '&row-type=' + row_type;
    }
    if (instance_type != null) {
      url = url + '&instance-type=' + instance_type;
    }
    if (inFocus.attr('data-row-type') != null) {
      url = url + '&rowType=' + inFocus.attr('data-row-type');
    }
    if (!!inFocus.attr('data-tree-element-operation')) {
      url = url + '&tree-element-operation=' + inFocus.attr('data-tree-element-operation');
    }
    if (!!inFocus.attr('data-tree-version-id')) {
      url = url + '&tree-version-id=' + inFocus.attr('data-tree-version-id');
    }
    if (!!inFocus.attr('data-tree-version-element-element-link')) {
      url = url + '&tree-version-element-element-link=' + inFocus.attr('data-tree-version-element-element-link');
    }
    if (!!inFocus.attr('data-tree-element-current-tve')) {
      url = url + '&tree-element-current-tve=' + inFocus.attr('data-tree-element-current-tve');
    }
    if (!!inFocus.attr('data-tree-element-previous-tve')) {
      url = url + '&tree-element-previous-tve=' + inFocus.attr('data-tree-element-previous-tve');
    }
    if (inFocus.attr('data-product-item-config-id')) {
      url = url + '&product_item_config_id=' + inFocus.attr('data-product-item-config-id');
    }
    debug(`url: ${url}`);
    if (tabWasClicked) {
      url = url + '&take_focus=true';
    } else {
      url = url + '&take_focus=false';
    }
    debug(`loadStandardDetails url: ${url}`);
    $('#search-result-details').load(url, function() {
      recordCurrentActiveTab(record_type);
      if (tabWasClicked) {
        if ($('.focus-details .give-me-focus')) {
          $('.focus-details .give-me-focus').focus();
          return;
        } else {
          return $('li.active a.tab').focus();
        }
      } else {
        debug('tab was NOT clicked loadStandardDetails');
        // do not switch focus - user may be just passing this record
        // not working on it
        return;
      }
    });
    // $('li.active a.tab').focus()   ## new
    debug('loadStandardDetails after load url');
    return event.preventDefault();
  };

  currentActiveTab = function(record_type) {
    debug("state of " + record_type + ` tab: ${$('body').attr('data-active-' + record_type + '-tab')} via currentActiveTab`);
    return $('body').attr('data-active-' + record_type + '-tab');
  };

  recordCurrentActiveTab = function(record_type) {
    return $('body').attr('data-active-' + record_type + '-tab', $('div#search-result-details ul.nav-tabs li.active a').attr('data-tab-name'));
  };

  searchResultFocus = function(event, $this) {
    debug('searchResultFocus starting from event: ' + event.type);
    $('#focus_id').val($this.find('a').attr('id'));
    if (!($this.hasClass('showing-details') || $this.hasClass('show-no-details'))) {
      debug('Changing focus: should show details');
      changeFocus(event, $this);
      $('#search-results.nothing-selected').removeClass('nothing-selected').addClass('something-selected');
      $('div#search-result-details').show();
    }
    return event.preventDefault();
  };

  window.searchResultFocus = searchResultFocus;

  changeFocus = function(event, inFocus) {
    debug(`changeFocus starting: id: ${inFocus.attr('id')}; event target: ${event.target}`);
    $('.showing-details').removeClass('showing-details');
    $('span.details-toggle').addClass('hidden');
    inFocus.addClass('showing-details');
    loadDetails(event, inFocus);
    inFocus.find('span.details-toggle.hidden').removeClass('hidden');
    return event.preventDefault();
  };

}).call(this);
