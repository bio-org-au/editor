
function setUpAuthorDuplicateOfTypeahead() {
   $('#author-duplicate-of-typeahead').typeahead({highlight: true}, {
        name: 'Authors',
        displayKey: 'value',
        source: authorsByNameDuplicateOf.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
          $('#author_duplicate_of_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
          $('#author_duplicate_of_id').val(datum.id);
        })
}

window.setUpAuthorDuplicateOfTypeahead = setUpAuthorDuplicateOfTypeahead;


// constructs the suggestion engine
window.authorsByNameDuplicateOf = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/authors/typeahead/on_name/exclude/current?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/authors/typeahead/on_name/duplicate_of/' + 
                                                       $('#author-duplicate-of-typeahead').attr('data-excluded-id') +
                                                       '?term='+encodeURIComponent(query) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
           }
          },
  limit: 100
});
 

// kicks off the loading/processing of `local` and `prefetch`
authorsByNameDuplicateOf.initialize();

window.authorsByNameDuplicateOf = authorsByNameDuplicateOf;
