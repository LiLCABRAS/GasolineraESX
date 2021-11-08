$(document).ready(function(){
    window.addEventListener('message', function( event ) {      
      if (event.data.action == 'open') {

        var counting;
        var fuel = event.data.fuel;        

        $('.tank-leiste-percent').text(Math.round(event.data.fuel) + '%');
        
        $('.tank-leiste-blue').css('width', ((Math.round(event.data.fuel) / 100) * 400) + 'px');

        $('.container').css('display', 'block');   

        if (counting) {
          $('.start_stop').text("Stop");
        } else {
          $('.start_stop').text("Start");
        }

        var inv;

        function start() {
          inv = setInterval(increase, 1000);
        }

        function increase() {
          if (counting) {
            if (fuel < 100) {
              fuel++;
  
              $('.tank-leiste-percent').text(Math.round(fuel) + '%');   
              $('#total').text("$ " + (Math.round(1.15 * (fuel - event.data.fuel) * 1000) / 1000).toFixed(2));     
              $('.tank-leiste-blue').animate({
                width: ((Math.round(fuel) / 100) * 400) + 'px'
              });
            }
          }
        }

        $( ".tank-botton-pay" ).click(function() {
          $.post('http://ps_tankstelle/escape', JSON.stringify({}));  
          $('.container').css('display', 'none');

          var perc_new = $('.tank-leiste-percent').text();
          var perc_formatted = perc_new.replace("%", "");    
          
          clearInterval(inv);

          $.post('http://ps_tankstelle/pay', JSON.stringify({
            new_perc: perc_formatted
          }));
        });

        $( ".start_stop" ).click(function() {
          counting = !counting;

          if (counting) {
            $('.start_stop').text("Stop");
            clearInterval(inv);
            fuel = event.data.fuel;
            start();
          } else {
            $('.start_stop').text("Start");
          }
        });

      } else {
        $('.container').css('display', 'none');
      }
    });

    $( ".close" ).click(function() {
      $('.container').css('display', 'none');
      $.post('http://ps_tankstelle/escape', JSON.stringify({}));
    });
  });