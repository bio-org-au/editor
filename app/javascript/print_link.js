// frozen_string_literal: true
//
// Handles print link functionality.
// Any link with the class 'print-link' will open its href in a new window
// and automatically trigger the browser's print dialog.
//
// Usage:
//   <%= link_to url, class: 'print-link', title: 'Print' do %>
//     <i class="fa fa-print"></i>
//   <% end %>
//

(function() {
  $(document).on("turbo:load", function() {
    $('body').on('click', '.print-link', function(event) {
      event.preventDefault();
      var url = $(this).attr('href');
      var printWindow = window.open(url, '_blank');
      if (printWindow) {
        printWindow.onload = function() {
          printWindow.print();
        };
      }
      return false;
    });
  });
}).call(this);
