

window.authorsByAbbrev = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: window.relative_url_root + '/authors/typeahead_on_abbrev?term=%QUERY',
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
window.authorsByAbbrev.initialize();

