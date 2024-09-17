
function setUpInstanceReferenceFoa() {
    alert("setUpInstanceReferenceFoa!!");
    $('#instance-reference-typeahead').typeahead(
        {highlight: true},
        {
        name: 'instance-reference',
        displayKey: 'value',
        source: referenceByCitation.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
            $('#instance_reference_id').val(datum.id);
            })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select.
        });
}

window.setUpInstanceReferenceFoa = setUpInstanceReferenceFoa 

// constructs the suggestion engine
window.referenceByCitation = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: window.relative_url_root + '/references/typeahead/on_citation?term=%QUERY',
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
referenceByCitation.initialize();

window.referenceByCitation = referenceByCitation;

