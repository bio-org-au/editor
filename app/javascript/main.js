// main.js

jQuery.ajaxSetup({
  'beforeSend': function (xhr) {
    xhr.setRequestHeader('Accept', 'text/javascript');
  }
});

function reportError(s) {
  try {
    console.log('Error: ' + s);
  } catch (e) {
  }
}

// ====================================== //
//  Document Ready                        //
// ====================================== //
$(document).on('turbo:load', function() {
  debug('Start of main.js document ready.');

  /* save editable fields automatically */
  $('a.add-to-query').click(function (event) {
    debug('a.add-to-query clicked');
    var val = $('#query').val();
    $('#query').val(val + ' ' + $(this).attr('data-search-component'));
    $('#query').focus();
  });

  $('tr.search-result > td.text.give-me-focus').focus();

  $('#show-tabindexes').click(function (event) {
    showTabIndexes();
    return (false);
  });

  // http://stackoverflow.com/questions/2196641/how-do-i-make-jquery-
  // contains-case-insensitive-including-jquery-1-8
  // "I would do something like this"
  $.expr[':'].containsIgnoreCase = function (n, i, m) {
    return jQuery(n).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0;
  };
  debug('End of main.js document ready.');
});  // end of document ready
// ===================================  end of document ready ================================================

var masterCheckboxClicked = function masterCheckboxClicked(event, $this) {
  debug('masterCheckboxClicked');
  var checked = $('div#search-results *.stylish-checkbox-checked').length;
  if (checked === 0) {
    // nth checked, so check everything
    $this.removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
    $('div#search-results *.stylish-checkbox-unchecked').removeClass('stylish-checkbox-unchecked').addClass('stylish-checkbox-checked');
  } else {
    // sth checked, so uncheck everything
    $this.removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
    $('div#search-results *.stylish-checkbox-checked').removeClass('stylish-checkbox-checked').addClass('stylish-checkbox-unchecked');
  }
};

var showTabIndexes = function showTabIndexes() {
  $('.tabindex-display').remove();
  $.each($('[tabindex]'), function (index, value) {
    debug('index: ' + index + '; value: ' + value + '; ' + $(value).attr('tabindex'));
    $(value).append('<span class="tabindex-display">(' + $(value).attr('tabindex') + ') </span>');
  })
};

function send(data, method, url, onDone) {
  $.ajax({
    method: method,
    url: url,
    data: JSON.stringify(data),
    contentType: "application/json",
    dataType: "json"
  }).done(function (respData) {
    debug(respData);
    onDone();
  }).fail(function (jqxhr, statusText) {
    if (jqxhr.status === 403) {
      debug("status 403 forbidden");
      alert("Apparently you're not allowed to do that.");
    } else if (jqxhr.responseJSON) {
      debug("Fail: " + statusText + ", " + jqxhr.responseJSON.error);
      alert(jqxhr.responseJSON.error);
    } else if (jqxhr.responseText) {
      debug("Fail: " + statusText + ", " + jqxhr.responseText);
      alert("That didn't work: " + statusText + ". " + jqxhr.responseText);
    }
  });
}

function markdown(text) {
  var converter = new showdown.Converter();
  return converter.makeHtml(text);
}
window.markdown = markdown;

function refreshTreeTab(event) {
  $('#instance-classification-tab').click();
  event.preventDefault();
  return false;
}

window.refreshTreeTab = refreshTreeTab;

function refreshPage() {
  location.reload();
}

window.refreshPage = refreshPage;

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

function matchCustom(params, data) {
  // If there are no search terms, return all of the data
  if ($.trim(params.term) === '') {
    return data;
  }

  if (typeof data.text === 'undefined') {
    return null;
  }

  // if it's multiple entries match and select them.
  if (params.term.indexOf(',') > -1) {
    multiMatch(params.term);
    return null;
  }

  if (data.text.toUpperCase().indexOf(params.term.toUpperCase()) === 0) {
    var modifiedData = $.extend({}, data, true);

    return modifiedData;
  }

  // Return `null` if the term should not be displayed
  return null;
}

function multiMatch(term) {
  var entries = [];
  term.split(',').forEach(function (el) {
    entries.push(el.trim())
  });
  $('.dist-select').val(entries).trigger('change').select2('close');
}

function initDistSelect() {
  $('.dist-select').select2({
    matcher: matchCustom,
    minimumInputLength: 1,
    closeOnSelect: true
  });
  $('.dist-select').on('select2:select', function (e) {
    console.log('Selected something');
    console.log(e.params.data);
    var m = e.params.data.id.split(' ')[0];
    $('option[value^=' + m + ']').attr('disabled', 'disabled');
    $('.dist-select').select2({
      matcher: matchCustom,
      minimumInputLength: 1,
      closeOnSelect: true
    });
    $('.select2-search__field').focus();
  });
  $('.dist-select').on('select2:unselect', function (e) {
    console.log('Selected something');
    console.log(e.params.data);
    var m = e.params.data.id.split(' ')[0];
    $('option[value^=' + m + ']').removeAttr('disabled');
    $('.dist-select').select2({
      matcher: matchCustom,
      minimumInputLength: 1,
      closeOnSelect: true
    });
    $('.select2-search__field').focus();
  });
}
window.initDistSelect = initDistSelect;

var toggleNext = function (el) {
  $(el).find('i').toggle();
  $(el).next('div').toggle(200);
};

window.toggleNext = toggleNext;

