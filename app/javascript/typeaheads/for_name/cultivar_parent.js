// Used on name edit form.
function setUpNameCultivarParentTypeahead() {
    debug('setUpNameCultivarParentTypeahead');
    if (typeof(nameParentSuggestionsForCultivar) != "undefined") {
        $("#name-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-name-id-parent",
            displayKey: function(obj) {
                return obj.value;
            },
            source: nameParentSuggestionsForCultivar.ttAdapter()})
            .on('typeahead:opened', function($e,datum) {
                debug('typeahead:opened'); })
            .on('typeahead:selected', function($e,datum) {
                debug('typeahead:selected');
                $('#name_parent_id').val(datum.id) })
            .on('typeahead:autocompleted', function($e,datum) {
                debug('typeahead:autocompeted');
                $('#name_parent_id').val(datum.id) })
        ;
    };
}

window.setUpNameCultivarParentTypeahead = setUpNameCultivarParentTypeahead;

// Provides a way to inject the current name id into the URL.
window.nameParentSuggestionsForCultivar = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/name/cultivar_parent?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/name/cultivar_parent?' +
                'name_id=' + $('#name-parent-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,'')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
window.nameParentSuggestionsForCultivar.initialize();

