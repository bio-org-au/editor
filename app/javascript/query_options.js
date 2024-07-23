// Generated by CoffeeScript 2.6.1
(function() {
  var appendToQueryField, buildQueryString, clearQueryField, queryOnSelectChanged, searchFieldChanged, populateList;

  $(document).on("turbo:load", function() {
    debug('Start of query_options.js turbo loaded');

    $('body').on('click', '.build-query-button', function(event) {
      return buildQueryString(event, $(this));
    });
    $('#search-field').change(function(event) {
      return searchFieldChanged(event, $(this));
    });
    $('body').on('change', 'select#query-on', function(event) {
      return queryonSelectChanged(event, $(this));
    });
    $('body').on('click', 'a.append-to-query-field', function(event) {
      return appendToQueryField(event, $(this));
    });
    $('body').on('click', 'a.clear-query-field', function(event) {
      return clearQueryField(event, $(this));
    });

    if (typeof showOrHideCultivarCommonCbox === 'function') {
      window.showOrHideCultivarCommonCbox($('#search-target-button-text').text().trim());
    }
  });


  window.queryonSelectChanged = function(event, $element) {
    debug(`queryonSelectChanged to: ${$element.val()} `);
    switch ($element.val()) {
      case 'author':
        setAuthorQueryOptions();
        break;
      case 'instance':
        setInstanceQueryOptions();
        break;
      case 'name':
        setNameQueryOptions();
        break;
      case 'reference':
        setReferenceQueryOptions();
        break;
      case 'tree':
        setTreeQueryOptions();
    }
    return $('#query-field').focus();
  };

  window.setAuthorQueryOptions = function() {
    debug('setAuthorQueryOptions');
    populateSelect($('select#query-field'), authorQueryOptions);
    populateList($('ul#query-list'), $('#author-query-options-storage').html());
    $('#query_common_and_cultivar').attr('disabled', true);
    return $('#query_common_and_cultivar_label').addClass('disabled');
  };

  window.setInstanceQueryOptions = function() {
    debug('setInstanceQueryOptions');
    populateSelect($('select#query-field'), instanceQueryOptions);
    populateList($('ul#query-list'), $('#instance-query-options-storage').html());
    $('#query_common_and_cultivar').attr('disabled', true);
    return $('#query_common_and_cultivar_label').addClass('disabled');
  };

  window.setNameQueryOptions = function() {
    debug('setNameQueryOptions');
    populateSelect($('select#query-field'), nameQueryOptions);
    populateList($('ul#query-list'), $('#name-query-options-storage').html());
    $('#query_common_and_cultivar').removeAttr('disabled');
    return $('#query_common_and_cultivar_label').removeClass('disabled');
  };

  window.setReferenceQueryOptions = function() {
    debug('setReferenceQueryOptions');
    populateSelect($('select#query-field'), referenceQueryOptions);
    populateList($('ul#query-list'), $('#reference-query-options-storage').html());
    $('#query_common_and_cultivar').attr('disabled', true);
    return $('#query_common_and_cultivar_label').addClass('disabled');
  };

  window.setTreeQueryOptions = function() {
    var allowBlank;
    debug('setTreeQueryOptions');
    allowBlank = false;
    populateSelect($('select#query-field'), treeQueryOptions, allowBlank);
    // no tree query options here
    $('#query_common_and_cultivar').attr('disabled', true);
    return $('#query_common_and_cultivar_label').addClass('disabled');
  };

  window.populateSelect = function(select, options, allowBlank = true) {
    var display, results, value;
    select.empty();
    if (allowBlank) {
      select.append("<option value=''></option>");
    }
    results = [];
    for (value in options) {
      display = options[value];
      results.push(select.append(`<option value='${value}'>${display}</option>`));
    }
    return results;
  };

  populateList = function(unorderedList, newContent) {
    debug('populateList');
    unorderedList.html('');
    return unorderedList.html(newContent);
  };

  searchFieldChanged = function(event, $element) {
    debug('searchFieldChanged');
    if ($('#search-field').val().match(/authors*:/)) {
      $('select#query-on').val('author');
    }
    if ($('#search-field').val().match(/instances*:/)) {
      $('select#query-on').val('instance');
    }
    if ($('#search-field').val().match(/name.usages*:/)) {
      $('select#query-on').val('instance');
    }
    if ($('#search-field').val().match(/names*:/)) {
      $('select#query-on').val('name');
    }
    if ($('#search-field').val().match(/refs*:/)) {
      return $('select#query-on').val('reference');
    }
  };

  buildQueryString = function(event, $element) {
    var search_string;
    debug('BuildQueryString');
    search_string = '';
    if ($('#name-full-name').val() || $('#name-simple-name').val() || $('#name-name-element').val() || $('#name-name-type').val() || $('#name-name-author').val()) {
      search_string += 'name: ';
    }
    if ($('#name-full-name').val()) {
      search_string += ` fn: ${$('#name-full-name').val()} `;
    }
    if ($('#name-simple-name').val()) {
      search_string += ` sn: ${$('#name-simple-name').val()} `;
    }
    if ($('#name-name-author').val()) {
      search_string += ` na: ${$('#name-name-author').val()} `;
    }
    if ($('#name-name-type').val()) {
      search_string += ` nt: ${$('#name-name-type').val()} `;
    }
    if ($('#name-name-element').val()) {
      search_string += ` ne: ${$('#name-name-element').val()} `;
    }
    if (search_string.length > 0) {
      search_string += ";";
    }
    if ($('#reference-citation').val()) {
      search_string += ` ci: ${$('#reference-citation').val()} `;
    }
    if ($('#reference-year').val()) {
      search_string += ` y: ${$('#reference-year').val()} `;
    }
    if ($('#reference-parent-title').val()) {
      search_string += ` pt: ${$('#reference-parent-title').val()} `;
    }
    if ($('#author-name').val()) {
      search_string += ` an: ${$('#author-name').val()} `;
    }
    $('#search-field').val(search_string);
    return event.preventDefault();
  };

  clearQueryField = function(event, $element) {
    $('#search-field').val('');
    return event.preventDefault();
  };

  appendToQueryField = function(event, $element) {
    $('#search-field').val($('#search-field').val() + ' ' + $element.attr('data-value'));
    return event.preventDefault();
  };

 
}).call(this);