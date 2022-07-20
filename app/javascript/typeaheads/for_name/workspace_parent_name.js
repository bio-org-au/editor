// Used on name edit form.
function setUpWorkspaceParentName() {

    $('#workspace_parent_name_typeahead').typeahead({highlight: true}, {
        name: 'workspace-parent-name-id',
        displayKey: function(obj) {
            return obj.value;
        },
        source: workspaceParentNameSuggestions.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh. Do not clear the hidden field on this event
            // because it will clear the field just by tabbing into the field.
        })
        .on('typeahead:selected', function($e,datum) {
            $('#workspace_parent_name_id').val(datum.id);
            var input = $('#workspace_parent_name_typeahead');
            var replaced = input.val().replace(/<.*>/g, '').trim();
            input.val(replaced);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#workspace_name_parent_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

window.setUpWorkspaceParentName = setUpWorkspaceParentName;

workspaceParentNameSuggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
        url: window.relative_url_root + '/suggestions/workspace/parent_name?term=%QUERY',
        replace: function (url, query) {
            return window.relative_url_root + '/suggestions/workspace/parent_name?' +
                'allow_higher_ranks=' + $('#allow_higher_ranks:checked').length + '&' +
                'name_id=' + $('#workspace_parent_name_typeahead').attr('data-name-id') + '&' +
                'parent_element_id=' + $('#workspace_parent_name_typeahead').attr('data-parent-element-id') + '&' +
                'term=' + encodeURIComponent(query.replace(/ -.*/, '')) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

workspaceParentNameSuggestions.initialize();

window.workspaceParentNameSuggestions = workspaceParentNameSuggestions;
