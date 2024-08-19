// Loader records let you insert a new record on the LHS under an existing record.
// By "record" I mean a gui entry ready to set up a new database record.
//

(function() {

  window.addNewRow = function(at_index, for_id, randomId, dataTabUrl) {
  // Get a reference to the table
  let tableRef = document.getElementById('search-results-table');
  let newRow = tableRef.insertRow(at_index + 1);
  $(newRow).attr('id', 'new-loader-name-'+randomId);
  $(newRow).addClass('new-record').addClass('new-loader-name').addClass('search-result').addClass('show-details');

  $(newRow).attr('data-record-type', 'loader-name');
  $(newRow).attr('data-record-id', for_id.toString());

  let tabUrl = dataTabUrl
  tabUrl = tabUrl.replace(/7007007007007007/,for_id);
  $(newRow).attr('data-tab-url', tabUrl);
  $(newRow).attr('data-edit-url', tabUrl);

  $(newRow).attr('tabindex', '3000');

  // Insert a cell in the row at index 0
  let firstCell = newRow.insertCell(0);
  $(firstCell).addClass('nsl-tiny-icon-container').addClass('takes-focus width-1-percent');

  let secondCell = newRow.insertCell(1);
  $(secondCell).addClass('text').addClass('takes-focus').addClass('name');
  $(secondCell).addClass('main-content').addClass('give-me-focus');
  $(secondCell).addClass('min-width-40-percent').addClass('max-width-100-percent').addClass('width-90-percent');
  // Append a text node to the cell
  let label = document.createTextNode('New Accepted or Excluded Loader Name');
  let link = document.createElement('a');
  $(link).addClass('show-details-link');
  $(link).attr('title','New loader name record. Select to see details');
  $(link).attr('tabindex','1000');
  link.appendChild(label)
  secondCell.appendChild(link);
  };

}).call(this);


