function setUpReferenceDuplicateOf() {
    $('#reference-duplicate-of-typeahead').typeahead({highlight: true}, {
      name: 'reference-duplicate-of-id',
      displayKey: 'value',
      source: referenceByCitationForDuplicate.ttAdapter()})
      .on('typeahead:selected', function($e,datum) {
				 $('#reference_duplicate_of_id').val(datum.id);
			})
      .on('typeahead:autocompleted', function($e,datum) {
				 $('#reference_duplicate_of_id').val(datum.id);
			})
      .on('typeahead:closed', function($e,datum) {
        // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
        // Users must select or autocomplete.
      });
}

window.setUpReferenceDuplicateOf = setUpReferenceDuplicateOf;



// constructs the suggestion engine
window.referenceByCitationForDuplicate = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/references/typeahead/on_citation/for_duplicate/?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/references/typeahead/on_citation/for_duplicate/' + 
                                                       $('#reference-duplicate-of-typeahead').attr('data-excluded-id') +
                                                       '?term='+encodeURIComponent(query) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
           }
          },
  limit: 100
});
 
referenceByCitationForDuplicate.initialize();

window.referenceByCitationForDuplicate = referenceByCitationForDuplicate;


