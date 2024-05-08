

function setUpLoaderNameMatchIntendedTreeParentTypeahead() {
        $("#loader-name-match-intended-tree-parent-name-typeahead").typeahead({highlight: true}, {
            name: "loader-name-match-intended-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: loaderNameMatchIntendedTreeParentSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('intended tree parentparent typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              debug('intended tree parentparent typeahead:selected');
              $('#loader_name_match_intended_tree_parent_name_id').val(datum.id);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              debug('intended tree parent typeahead:autocompeted');
              $('#loader_name_match_intended_tree_parent_name_id').val(datum.id);
            }
            )
        ;
}

window.setUpLoaderNameMatchIntendedTreeParentTypeahead = setUpLoaderNameMatchIntendedTreeParentTypeahead;

// Provides a way to inject the current loader name id into the URL.
// Using the replace function to strip off the loader name's rank, which
// is delimited by a pipe symbol (|).
window.loaderNameMatchIntendedTreeParentSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/loader/name/match/suggestions/for_intended_tree_parent/index?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/loader/name/match/suggestions/for_intended_tree_parent/index?' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,'')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

window.loaderNameMatchIntendedTreeParentSuggestions.initialize();


