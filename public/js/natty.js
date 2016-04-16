Date.prototype.getShortMonth = function () {
   return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][this.getMonth()];
};

Number.prototype.zeropad = function(n) {
   var str = "" + this;
   var len = n - str.length;
   var pad = "";
   while (len-- > 0) {
      pad += "0";
   }
   return pad + str;
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
            },
            error: function(xhr, status, err) {
               alert(xhr.status + " " + xhr.statusText);
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
                       + d.getHours().zeropad(2) + ":" + d.getMinutes().zeropad(2);
   });
});
