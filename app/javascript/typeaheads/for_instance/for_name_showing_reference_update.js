function setUpInstanceInstanceForNameShowingReferenceUpdate() {

    $('#instance-instance-for-name-showing-reference-typeahead').typeahead({highlight: true}, {
        name: 'instance-instance-for-name-showing-reference-typeahead',
        displayKey: 'value',
        source: instanceForNameShowingReferenceUpdate.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh.
            // Do not clear the hidden field on this event
            // because it will clear the field just by tabbing 
            // into the field.
            // $('#instance_cites_id').val('');
        })
        .on('typeahead:selected', function($e,datum) {
            $('#instance_cites_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#instance_cites_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

window.setUpInstanceInstanceForNameShowingReferenceUpdate = setUpInstanceInstanceForNameShowingReferenceUpdate;


// Get a list of references in instances of the name
instanceForNameShowingReferenceUpdate = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/instances/for_name_showing_reference?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/instances/for_name_showing_reference_to_update_instance?instance_id=' +
                $('#instance_id').val() +
                '&term=' + encodeURIComponent(query) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()

        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
instanceForNameShowingReferenceUpdate.initialize();

window.instanceForNameShowingReferenceUpdate = instanceForNameShowingReferenceUpdate;

