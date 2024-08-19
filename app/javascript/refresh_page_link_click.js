(function() {
  var refreshPageLinkClick;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#refresh-page-from-details-link', function(event) {
      return refreshPageLinkClick(event, $(this));
    });
    $('body').on('click', '.refresh-page-link', function(event) {
      return refreshPageLinkClick(event, $(this));
    });

  });

  refreshPageLinkClick = function(event, $element) {
    return location.reload();
  };

}).call(this);



