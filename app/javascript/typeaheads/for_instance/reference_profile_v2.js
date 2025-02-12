
function setUpInstanceReferenceProfileV2(profileItemId) {
    const divId = 'instance-reference-typeahead-'+profileItemId;
    if ($('#' + divId).length === 0) {
        console.warn('Element with ID ' + divId + ' does not exist.');
        return;  // Exit the function if the element is not found
    }
    // Use the passed divId to initialize typeahead for that specific input element
    $('#' + divId).typeahead(
        {highlight: true},
        {
            name: 'instance-reference',
            displayKey: 'value',
            source: referenceByCitation.ttAdapter()
        })
        .on('typeahead:selected', function($e, datum) {
            $('#reference-id-hidden-' + profileItemId).val(datum.id);
        })
        .on('typeahead:closed', function($e, datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select.
        });
}


window.setUpInstanceReferenceProfileV2 = setUpInstanceReferenceProfileV2 

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

