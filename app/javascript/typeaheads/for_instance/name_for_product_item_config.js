function setUpInstanceForProductItemConfig(productItemConfigId, instanceId) {
  const divId = 'instance-product-item-config-typeahead-'+productItemConfigId;
  if ($('#' + divId).length === 0) {
      console.warn('Element with ID ' + divId + ' does not exist.');
      return;  // Exit the function if the element is not found
  }
  // Use the passed divId to initialize typeahead for that specific input element
  $('#' + divId).typeahead(
      {highlight: true},
      {
          name: 'instance-product-item-config-'+productItemConfigId,
          displayKey: 'value',
        source: instanceByProductItemConfig.ttAdapter()
      })
      .on('typeahead:selected', function($e, datum) {
        fetch(window.relative_url_root + '/profile_items/' + datum.profile_item_id + '/details?instance_id=' + instanceId, {
          headers: {
            'Accept': 'text/vnd.turbo-stream.html'
          },
          credentials: "same-origin"
        })
        .then(response => response.text())
        .then(html => Turbo.renderStreamMessage(html));
      })
      .on('typeahead:closed', function($e, datum) {
          // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
          // Users must select.
      });
}

window.setUpInstanceForProductItemConfig = setUpInstanceForProductItemConfig

// constructs the suggestion engine
window.instanceByProductItemConfig = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: {url: window.relative_url_root + '/instances/for_product_item_config?term=%QUERY',
    replace: function(url, query) {
        return window.relative_url_root + '/instances/for_product_item_config?product_item_config_id=' +
        $('#product_item_config_id').val() +
        '&term=' + encodeURIComponent(query)
    }
  },
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
instanceByProductItemConfig.initialize();

window.instanceByProductItemConfig = instanceByProductItemConfig;

