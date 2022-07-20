
function setUpInstanceReferenceExcludingCurrent() {
    $('#instance-reference-typeahead').typeahead(
        {highlight: true},
        {
        name: 'instance-reference',
        displayKey: 'value',
        source: referenceByCitationExcludingCurrent.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
            $('#instance_reference_id').val(datum.id);
            })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select.
        });
}

window.setUpInstanceReferenceExcludingCurrent = setUpInstanceReferenceExcludingCurrent;


// constructs the suggestion engine
window.referenceByCitationExcludingCurrent = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/references/typeahead/on_citation/exclude/current?term=%QUERY',
           replace: function(url,query) {
                     return window.relative_url_root + '/references/typeahead/on_citation/exclude/' + 
                                                       $('#instance-reference-typeahead').attr('data-excluded-id') +
                                                       '?term='+encodeURIComponent(query) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
           }
          },
  limit: 100
});
 
referenceByCitationExcludingCurrent.initialize();

window.referenceByCitationExcludingCurrent = referenceByCitationExcludingCurrent;
