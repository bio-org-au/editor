
function setUpOrchidParentTypeahead() {
        $("#orchid-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-orchid-id-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: orchidParentSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('parent typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              debug('parent typeahead:selected');
              $('#orchid_parent_id').val(datum.id);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              debug('parent typeahead:autocompeted');
                $('#orchid_parent_id').val(datum.id) })
        ;
}

window.setUpOrchidParentTypeahead = setUpOrchidParentTypeahead;

// Provides a way to inject the current orchid id into the URL.
// Using the replace function to strip off the Name's rank, which
// is delimited by a pipe symbol (|).
orchidParentSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/orchids/parent_suggestions?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/orchids/parent_suggestions?' +
                'orchid_id=' + $('#orchid-parent-typeahead').attr('data-orchid-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,'')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

orchidParentSuggestions.initialize();

window.orchidParentSuggestions = orchidParentSuggestions;

