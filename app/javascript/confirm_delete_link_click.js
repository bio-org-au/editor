(function() {
  $(document).on("turbo:load", function() {
    $('body').on('click', 'a.confirm-delete-btn', function() {
      var $btn = $(this);
      $btn.attr('disabled', 'disabled')
          .prepend(document.createTextNode(' '))
          .prepend($('<i>').addClass('fa fa-spinner fa-spin'));
      $btn.siblings('.cancel-link').attr('disabled', 'disabled');
    });
  });
}).call(this);
