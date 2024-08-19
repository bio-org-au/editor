(function() {
  var reviewResultKeyNavigation, searchResultsCheckedCount;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#master-checkbox.stylish-checkbox', function(event) {
      return masterCheckboxClicked(event, $(this));
    });

  });

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

}).call(this);







