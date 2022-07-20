
function setUpReferenceParent() {
    $('#reference-parent-typeahead').typeahead({highlight: true}, {
      name: 'reference-parent',
      displayKey: 'value',
      source: referenceByCitationForParent.ttAdapter()})
      .on('typeahead:selected', function($e,datum) {
        $('#reference_parent_id').val(datum.id);
      })
      .on('typeahead:autocompleted', function($e,datum) {
        $('#reference_parent_id').val(datum.id);
      })
      .on('typeahead:closed', function($e,datum) {
        // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
        // Users must select or autocomplete.
      });
}

window.setUpReferenceParent = setUpReferenceParent;


// constructs the suggestion engine
window.referenceByCitationForParent = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/references/typeahead/on_citation/for_parent/?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/references/typeahead/on_citation/for_parent?id=' + 
                                                       $('#reference-parent-typeahead').attr('data-current-id') +
                                                       '&ref_type_id=' + $('#reference_ref_type_id').val() +
                                                       '&term='+encodeURIComponent(query)  + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
           }
          },
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
referenceByCitationForParent.initialize();


window.referenceByCitationForParent = referenceByCitationForParent;
