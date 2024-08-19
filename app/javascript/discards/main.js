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
  if (debugSwitch === true) {
  debug('Start of main.js document ready.');
  }

  /* save editable fields automatically */
  $('a.add-to-query').click(function (event) {
    debug('a.add-to-query clicked');
    var val = $('#query').val();
    $('#query').val(val + ' ' + $(this).attr('data-search-component'));
    $('#query').focus();
  });

  $('tr.search-result > td.text.give-me-focus').focus();

  // http://stackoverflow.com/questions/2196641/how-do-i-make-jquery-
  // contains-case-insensitive-including-jquery-1-8
  // "I would do something like this"
  $.expr[':'].containsIgnoreCase = function (n, i, m) {
    return jQuery(n).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0;
  };
  if (debugSwitch === true) {
  debug('End of main.js document ready.');
  }
});  // end of document ready
// ===================================  end of document ready ================================================

function markdown(text) {
  var converter = new showdown.Converter();
  return converter.makeHtml(text);
}
window.markdown = markdown;

