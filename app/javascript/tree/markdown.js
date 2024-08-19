(function() {

  function markdown(text) {
  var converter = new showdown.Converter();
  return converter.makeHtml(text);
  }
  window.markdown = markdown;

}).call(this);
  
  
