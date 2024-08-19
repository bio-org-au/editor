(function() {
  var showTabIndexes;

  $(document).on('turbo:load', function() {

    $('#show-tabindexes').click(function (event) {
      showTabIndexes();
      return (false);
    });

  });  // end of document ready


  var showTabIndexes = function showTabIndexes() {
    $('.tabindex-display').remove();
    $.each($('[tabindex]'), function (index, value) {
      debug('index: ' + index + '; value: ' + value + '; ' + $(value).attr('tabindex'));
      $(value).append('<span class="tabindex-display">(' + $(value).attr('tabindex') + ') </span>');
    })
  };

}).call(this);

