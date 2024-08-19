(function() {
  var createInstancesBatchSubmit, createMatchesBatchSubmit;

  $(document).on("turbo:load", function() {

    $('body').on('click', '#create-instances-batch-submit', function(event) {
      return createInstancesBatchSubmit(event, $(this));
    });
    $('body').on('click', '#create-matches-batch-submit', function(event) {
      return createMatchesBatchSubmit(event, $(this));
    });

  });

  createMatchesBatchSubmit = function(event, $the_element) {
    $('#search-result-details-info-message-container').html('Working....');
    return true;
  };

  createInstancesBatchSubmit = function(event, $the_element) {
    $('#search-result-details-info-message-container').html('Working....');
    return true;
  };

}).call(this);



