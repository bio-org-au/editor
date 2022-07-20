
function setUpLoaderBatchDefaultReferenceTypeahead() {

        $("#loader-batch-default-reference-typeahead").typeahead({highlight: true}, {
            name: "loader-batch-default-reference-id",
            displayKey: function(obj) {
                return obj.value;
            },
            source: loaderBatchDefaultReferenceSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('default ref typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              debug('default ref typeahead:selected');
              $('#loader_batch_default_reference_id').val(datum.id);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              debug('default ref typeahead:autocompeted');
                $('#loader_batch_default_reference_id').val(datum.id) })
        ;
}

window.setUpLoaderBatchDefaultReferenceTypeahead = setUpLoaderBatchDefaultReferenceTypeahead;

// Provides a way to inject the current loader name id into the URL.
// Using the replace function to strip off the loader name's rank, which
// is delimited by a pipe symbol (|).
loaderBatchDefaultReferenceSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/loader/batches/default_reference_suggestions?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/loader/batches/default_reference_suggestions?' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,'')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

loaderBatchDefaultReferenceSuggestions.initialize();

window.loaderBatchDefaultReferenceSuggestions = loaderBatchDefaultReferenceSuggestions;

