
function setUpLoaderNameParentTypeahead() {
        $("#loader-name-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-loader-name-id-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: loaderNameParentSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('parent typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              debug('parent typeahead:selected');
              $('#loader_name_parent_id').val(datum.id);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              debug('parent typeahead:autocompeted');
                $('#loader_name_parent_id').val(datum.id) })
        ;
}

window.setUpLoaderNameParentTypeahead = setUpLoaderNameParentTypeahead;

// Provides a way to inject the current loader name id into the URL.
// Using the replace function to strip off the loader name's rank, which
// is delimited by a pipe symbol (|).
loaderNameParentSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/loader_names/parent_suggestions?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/loader_names/parent_suggestions?' +
                'loader_batch_id=' + $('#loader-name-parent-typeahead').attr('data-loader-batch-id') + '&' +
                'loader_name_id=' + $('#loader-name-parent-typeahead').attr('data-loader-name-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,'')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

loaderNameParentSuggestions.initialize();

window.loaderNameParentSuggestions = loaderNameParentSuggestions;

