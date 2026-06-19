
function setUpInstanceNameChange(instanceId) {
  var changeNameBloodhound = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
      url: window.relative_url_root + '/instances/' + instanceId + '/name/typeahead?term=%QUERY',
      wildcard: '%QUERY'
    },
    limit: 50
  });
  changeNameBloodhound.initialize();

  $('#instance-name-change-typeahead').typeahead(
    { highlight: true },
    { name: 'name-change', displayKey: 'value', source: changeNameBloodhound.ttAdapter() }
  )
  .on('typeahead:selected', function($e, datum) {
    $('#instance-change-name-id').val(datum.id);
  })
  .on('typeahead:autocompleted', function($e, datum) {
    $('#instance-change-name-id').val(datum.id);
  })
  .on('typeahead:closed', function($e, datum) {
    // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
    // Users must select or autocomplete.
  });
}

window.setUpInstanceNameChange = setUpInstanceNameChange;
