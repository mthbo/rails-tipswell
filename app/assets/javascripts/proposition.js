$(function(){

  $('#proposition-toggle').on('click', function(event) {
    event.preventDefault();
    $('#proposition-details').slideToggle('fast');
    $('#proposition-toggle p').toggleClass('hidden');
  });

});