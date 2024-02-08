
function setUpNameParentTypeahead() {
    if (typeof(nameParentSuggestions) != "undefined") {
        $("#name-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-name-id-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: nameParentSuggestions.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
              debug('parent typeahead:opened');
            })
            .on('typeahead:selected', function($e,datum) {
              $('#name_parent_id').val(datum.id);
              $('#name_family_id').val(datum.family_id);
              $("#name-family-typeahead").typeahead('val', datum.family_value);

            })
            .on('typeahead:autocompleted', function($e,datum) {
              $('#name_parent_id').val(datum.id)
              $('#name_family_id').val(datum.family_id);
              $("#name-family-typeahead").typeahead('val', datum.family_value);
            })
        ;
    };
}

window.setUpNameParentTypeahead = setUpNameParentTypeahead;

// Provides a way to inject the current name id into the URL.
// Using the replace function to strip off the Name's rank, which
// is delimited by a pipe symbol (|).
window.nameParentSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/names/name_parent_suggestions?format=js&term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/names/name_parent_suggestions?format=js&' +
                'name_id=' + $('#name-parent-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,'')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

window.nameParentSuggestions.initialize();

