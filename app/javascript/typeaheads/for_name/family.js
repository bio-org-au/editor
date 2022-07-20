function setUpNameFamilyTypeahead() {
    if (typeof(nameFamilySuggestions) != "undefined") {
        $("#name-family-typeahead").typeahead({highlight: true}, {
            name: "familys",
            displayKey: function (obj) {
                return obj.value;
            },
            source: nameFamilySuggestions.ttAdapter()
        })
            .on('typeahead:opened', function ($e, datum) {
              debug('family typeahead:opened');
            })
            .on('typeahead:selected', function ($e, datum) {
              debug('family typeahead:selected');
                $('#name_family_id').val(datum.id)
            })
            .on('typeahead:autocompleted', function ($e, datum) {
              debug('family typeahead:autocompeted');
                $('#name_family_id').val(datum.id)
            })
        ;
    }
    ;
}

window.setUpNameFamilyTypeahead = setUpNameFamilyTypeahead;

// Provides a way to inject the current name id into the URL.
// Using the replace function to strip off the Name's rank, which
// is delimited by a pipe symbol (|).
nameFamilySuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
        url: window.relative_url_root + '/names/name_family_suggestions?term=%QUERY',
        replace: function (url, query) {
            return window.relative_url_root + '/names/name_family_suggestions?' +
                'name_id=' + $('#name-family-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/, ''))  + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

nameFamilySuggestions.initialize();

