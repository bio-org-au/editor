(function() {
  var dropdownSubmenuClick, hideDetails, hideSearchResultDetailsIfMenusOpen, showSearchResultDetailsIfMenusClosed;

  $(document).on("turbo:load", function() {
  // Do NOT close the menu when submenu is clicked.

    $('body').on('click', 'span.details-toggle', function(event) {
      return hideDetails(event, $(this));
    });

    $('body').on('click', '#switch-off-details-tab', function(event) {
      return hideDetails(event, $(this));
    });

  });


  dropdownSubmenuClick = function(event, $element) {
    event.preventDefault();
    return event.stopPropagation();
  };

  showSearchResultDetailsIfMenusClosed = function() {
    debug('showSearchResultDetailsIfMenusClosed');
    if ($('li.dropdown.open').length === 0) {
      return $('#search-result-details').show();
    }
  };

  hideSearchResultDetailsIfMenusOpen = function() {
    debug('hideSearchResultDetailsIfMenusOpen');
    if ($('li.dropdown.open').length > 0) {
      return $('#search-result-details').hide();
    }
  };

  hideDetails = function(event, $this) {
    debug('Hiding details');
    $this.addClass('hidden');
    $('.showing-details').removeClass('showing-details');
    $('div#search-result-details').hide();
    $('#search-results.something-selected').removeClass('something-selected').addClass('nothing-selected');
    return event.preventDefault();
  };

}).call(this);
