(function() {
  var nameRankIdChanged;

  $(document).on("turbo:load", function() {
    
    $('body').on('change', '#name_name_rank_id', function(event) {
      return nameRankIdChanged(event, $(this));
    });

  });

  nameRankIdChanged = function(event, $element) {
    if ($element.val() === "") {
      $('.requires-rank').attr('disabled', 'true');
      $('input.requires-rank').removeClass('enabled').addClass('disabled');
      return $('.hide-if-rank').removeClass('hidden');
    } else {
      $('.requires-rank').removeAttr('disabled');
      $('input.requires-rank').removeClass('disabled').addClass('enabled');
      return $('.hide-if-rank').addClass('hidden');
    }
  };

}).call(this);



