(function() {
  var matchCustom, multiMatch, initDistSelect;

function matchCustom(params, data) {
  // If there are no search terms, return all of the data
  if ($.trim(params.term) === '') {
    return data;
  }

  if (typeof data.text === 'undefined') {
    return null;
  }

  // if it's multiple entries match and select them.
  if (params.term.indexOf(',') > -1) {
    multiMatch(params.term);
    return null;
  }

  if (data.text.toUpperCase().indexOf(params.term.toUpperCase()) === 0) {
    var modifiedData = $.extend({}, data, true);

    return modifiedData;
  }

  // Return `null` if the term should not be displayed
  return null;
}

function multiMatch(term) {
  var entries = [];
  term.split(',').forEach(function (el) {
    entries.push(el.trim())
  });
  $('.dist-select').val(entries).trigger('change').select2('close');
}

function initDistSelect() {
  $('.dist-select').select2({
    matcher: matchCustom,
    minimumInputLength: 1,
    closeOnSelect: true
  });
  $('.dist-select').on('select2:select', function (e) {
    console.log('Selected something');
    console.log(e.params.data);
    var m = e.params.data.id.split(' ')[0];
    $('option[value^=' + m + ']').attr('disabled', 'disabled');
    $('.dist-select').select2({
      matcher: matchCustom,
      minimumInputLength: 1,
      closeOnSelect: true
    });
    $('.select2-search__field').focus();
  });
  $('.dist-select').on('select2:unselect', function (e) {
    console.log('Selected something');
    console.log(e.params.data);
    var m = e.params.data.id.split(' ')[0];
    $('option[value^=' + m + ']').removeAttr('disabled');
    $('.dist-select').select2({
      matcher: matchCustom,
      minimumInputLength: 1,
      closeOnSelect: true
    });
    $('.select2-search__field').focus();
  });
}

  window.initDistSelect = initDistSelect;

}).call(this);
