// Used on name edit form.
function setUpNameDuplicateOf() {

    $('#duplicate-of-typeahead').typeahead({highlight: true}, {
        name: 'name-duplicate-of-id',
        displayKey: 'value',
        source: nameDuplicateSuggestions.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh. Do not clear the hidden field on this event
            // because it will clear the field just by tabbing into the field.
        })
        .on('typeahead:selected', function($e,datum) {
            $('#name_duplicate_of_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#name_duplicate_of_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

window.setUpNameDuplicateOf = setUpNameDuplicateOf;

nameDuplicateSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/name/duplicate?format=js&term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/name/duplicate?format=js&' +
                'name_id=' + $('#duplicate-of-typeahead').attr('data-name-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))  + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

nameDuplicateSuggestions.initialize();


window.nameDuplicateSuggestions = nameDuplicateSuggestions;
