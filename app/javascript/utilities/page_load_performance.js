(function() {

  $(document).on("turbo:load", function() {
  
    // Based on
    // https://www.silvestar.codes/articles/how-to-measure-page-loading-time-with-performance-api/
    window.addEventListener('load', () => {
      const pageEnd = performance.mark('pageEnd')
      const loadTime = Math.round( 1000 * (pageEnd.startTime / 1000) )/1000

      document.querySelector('.js-perf').innerHTML += `page: ${loadTime}s`
    })

  });

}).call(this);

