Date.prototype.getShortMonth = function () {
   return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][this.getMonth()];
};

// ===========================================================================
// Player online buttons
// ===========================================================================

$(document).ready(function () {
   var q = $.when();
   $('.Player').click(function (e) {
      e.preventDefault();
      var $row = $(this);
      var $form = $row.find('form');

      q = q.then(
         $.ajax({
            method: "POST",
            url: $form.attr('action'),
            success: function(res) {
               if (res === '1') {
                  $row.addClass('online');
               }
               else {
                  $row.removeClass('online');
               }
            }
         })
      )
   });
});

// ===========================================================================
// Localise <time> elements
// ===========================================================================

$(document).ready(function () {
   $('time.datetime').each(function () {
      var d = new Date(this.dateTime);
      this.textContent = d.getShortMonth() + " " + d.getDate() + " "
                       + d.getHours() + ":" + d.getMinutes();
   });
});
