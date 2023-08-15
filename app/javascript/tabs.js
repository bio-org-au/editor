  debug = function(s) {
    var error;
    try {
      if (debugSwitch === true) {
        return console.log('debug: ' + s);
      }
    } catch (error1) {
      error = error1;
    }
  };

function getContentOnDemand(theThis) {
  debug("getContentOnDemand for id: " + $(theThis).attr('id') + " and context: " + $(theThis).attr('data-load-context'));
  var targetID = $(theThis).attr('data-load-context');
  if (targetID.match("-for-dynamic-target-")) {
    var ray = targetID.split("-for-dynamic-target-");
    var displayElementID = ray[0];
    debug("displayElementID: "+ displayElementID);
  } else {
    var displayElementID = targetID;
  }
  if (displayElementID === undefined || displayElementID == '') {
    debug("displayElementID is undefined or empty - you need to set it ");
  } else {
      debug("we have displayElementID: "+ displayElementID);
      var $targetElement = $('#' + displayElementID);
      if ($targetElement.attr('data-loaded') === undefined) {
        debug("No entry for " + displayElementID);
        debug("You need to add a target div in search/tab_inners/_*target_divs.html or similar");
      }
      if ($targetElement.attr('data-loaded') == 'false') {
        debug('data-loaded false, so loading now');
        debug("displayElementID: "+ displayElementID);
        debug("targetID: "+ targetID);
        debug("$targetElement.attr('id'): "+ $targetElement.attr('id'));
        $targetElement.html('Loading...');
        $.get(window.relative_url_root + "/search/help/" + targetID, function (data) {
          $targetElement.html(data);
          $targetElement.attr('data-loaded', 'true');
        }, 'html');
      }
      $targetElement.removeClass('hidden');
  }

};


function setActiveHelpOnLoad() {
  showHelpForSearchTarget(getActiveHelpIdentifier());
}

function showHelpForSearchTarget(helpElement) {
  if (debugSwitch === true) {
    debug('showHelpForSearchTarget: ' + helpElement);
  }
  $('#help-search-tab-container-link').attr('data-load-context', helpElement);
  $('.search-help').addClass('hidden');
  $('#' + helpElement).removeClass('hidden');
  makeCurrentlyVisibleHelpMatchTarget();
}

window.showOrHideCultivarCommonCbox = function(searchTarget) {
  if (searchTarget == 'Names' || searchTarget == 'Names plus instances') {
    $('#set-include-common-and-cultivar').removeClass('hidden');
    $('#trailing-pipe-for-set-include-common-and-cultivar').removeClass('hidden');
  } else {
    $('#set-include-common-and-cultivar').addClass('hidden');
    $('#trailing-pipe-for-set-include-common-and-cultivar').addClass('hidden');
  }
}


function makeCurrentlyVisibleHelpMatchTarget() {
  if (helpTabVisible()) {
    $('#help-search-tab-container-link').click();
  }
  ;
}

function helpTabVisible() {
  return $('#help-search-tab-container-link').closest('li').hasClass('active');
}

function getActiveHelpIdentifier() {
  return $('ul#search-target-list li a')
    .filter(function (index) {
      return $(this).text().trim().toLowerCase() === $('#search-target-button-text')
        .text()
        .trim()
        .toLowerCase()
    }).first().attr('data-help');
}

// //////////////////////////////////////////////////////////////
// Section                                                     //
// //////////////////////////////////////////////////////////////

function setActiveExamplesOnLoad() {
  if (debugSwitch === true) {
    debug("setActiveExamplesOnLoad");
  }
  showExamplesForSearchTarget(getActiveExamplesIdentifier());
}

function showExamplesForSearchTarget(examplesElement) {
  $('#example-search-tab-container-link').attr('data-load-context', examplesElement);
  $('.search-examples').addClass('hidden');
  $('#' + examplesElement).removeClass('hidden');
  makeCurrentlyVisibleExamplesMatchTarget();
}

function makeCurrentlyVisibleExamplesMatchTarget() {
  if (examplesTabVisible()) {
    $('#example-search-tab-container-link').click();
  }
  ;
}

function examplesTabVisible() {
  return $('#example-search-tab-container-link').closest('li').hasClass('active');
}

function hideResults() {
  $('.main-body-container').addClass('hidden');
  $('#search-result-details').addClass('hidden');
}

function showHelpTarget(target) {
  hideResults();
  debug("showHelpTarget: " + target);
  $(target).removeClass('hidden');
}

function getActiveExamplesIdentifier() {
  return $('ul#search-target-list li a')
    .filter(function (index) {
      return $(this).text().trim().toLowerCase() === $('#search-target-button-text')
        .text()
        .trim()
        .toLowerCase()
    }).first().attr('data-examples');
}

$( document ).on('turbo:load', function() {
  if (debugSwitch === true) {
    console.log('tabs.js turbo:load event');
  }

  $('ul#search-results-tabset li a.main-body-tab-link').on('click', function (e) {
    debug('.main-body-tab-link clicked; non-advanced containers will be HIDDEN.');
    $('ul#search-results-tabset li').removeClass('active');
    $(this).parent('li').addClass('active');
    $('.main-body-container').addClass('hidden');
    $('div#search-result-details').addClass('hidden');
    var targetElement = $(this).attr('data-target-element');
    if (targetElement !== undefined) {
      $.each($(this).attr('data-target-element').split(","), function (index, value) {
        $(value).removeClass('hidden');
      });
    }
    e.preventDefault();
  });

  // Show search result details when search results are displayed
  // but only if there are details to show.
  $('#search-results-tab-container-link').on('click', function (e) {
    if ($('#search-result-details .focus-details').length > 0) {
      $('div#search-result-details').removeClass('hidden');
    }
  });

  $("select#name-advanced-search-name-type-options")
    .change(function () {
      var str = "";
      $("select#name-advanced-search-name-type-options option:selected").each(function () {
        if (str.trim().length == 0) {
          str = $(this).val();
        } else {
          str += ", " + $(this).val()
        }
      });
      $("input#name-advanced-search-name-type-list").val(str);
    });

  $("#search-target-list").on("click", function (e) {
    if (e.target && e.target.nodeName == "A") {
      debug('setting search-target: e.target.innerHTML:' + e.target.innerHTML);
      document.getElementById('search-target-button-text').innerHTML = e.target.innerHTML;
      document.getElementById('query-target').value = e.target.innerHTML;
      showHelpForSearchTarget(e.target.dataset.help);
      showExamplesForSearchTarget(e.target.dataset.examples);
      showOrHideCultivarCommonCbox(e.target.innerHTML);
      e.preventDefault()
    }
  });

  $('a.search-help-link').on('click', function (e) {
    var targetElement = e.target.dataset.targetElement;
    getContentOnDemand(this);
    debug("after getContentOnDemand");
    showHelpTarget(targetElement);
    e.preventDefault();
  });

  $('a.search-examples-link').on('click', function (e) {
    var targetElement = e.target.dataset.targetElement;
    debug("targetElement: " + targetElement);
    getContentOnDemand(this);
    debug("after getContentOnDemand");
    debug("targetElement: " + targetElement);
    getContentOnDemand(this);
    //showHelpTarget(targetElement);
    e.preventDefault();
  });

  setActiveHelpOnLoad();
  setActiveExamplesOnLoad();
});

