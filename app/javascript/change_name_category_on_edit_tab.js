(function() {
  var changeNameCategoryOnEditTab;

  $(document).on("turbo:load", function() {

    $('body').on('click', '.change-name-category-on-edit-tab', function(event) {
      return changeNameCategoryOnEditTab(event, $(this), true);
    });

  });

  changeNameCategoryOnEditTab = function(event, $this, tabWasClicked) {
    debug('changeNameCategoryOnEditTab');
    $('#search-result-details').load($this.attr('data-edit-url'));
    return event.preventDefault();
  };

}).call(this);
