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

$(document).ajaxError(function (e, xhr) {
   alert(xhr.status + " " + xhr.statusText);
});

// ===========================================================================
// Player online buttons
// ===========================================================================

$(document).ready(function () {
   var q = $.when();
   var $players = $('.Player');

   $players.click(function (e) {
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
         })
      )
   });

   $('.Player-online--bulk input').click(function (e) {
      e.preventDefault();
      var $btn = $(this);
      var $form = $btn.closest('form');

      q = q.then(
         $.ajax({
            method: "POST",
            url: $form.attr('action'),
            success: function(res) {
               if ($btn.val() == 'All on') {
                  $players.addClass('online');
               }
               else if ($btn.val() == 'All off') {
                  $players.removeClass('online');
               }
            },
         })
      );
   });
});

// ===========================================================================
// Localise <time> elements
// ===========================================================================

$(document).ready(function () {
   $('time.datetime').each(function () {
      var d = new Date(this.dateTime);
      this.textContent = d.getShortMonth() + " " + d.getDate() + " " +
                       + d.getHours().zeropad(2) + ":" + d.getMinutes().zeropad(2);
   });

   $('.Fixture-form--start option').each(function () {
      var d = new Date(this.value);
      this.textContent = d.getHours().zeropad(2) + ":" + d.getMinutes().zeropad(2);
   });
});

// ===========================================================================
// Fixture create form
// ===========================================================================

$(document).ready(function () {
   var $form = $('.Fixture-form');
   if (!$form.size()) {
      return;
   }

   $('.Fixture-form--teams')
      .change(function () {
         $('#draw').empty();
         $('.Fixture-form--submit').addClass('hidden');

         var n = this.value;
         $('.Team').each(function (i) {
            if (i < n) {
               $(this).removeClass('hidden');
            }
            else {
               $(this).addClass('hidden');
               $(this).find('textarea').val('').attr('rows', 1);
            }
         });
      })
      .change();

   function reflowTeam () {
      this.rows = (this.value || '').split(/\n/).length;
   };
   $('.Team textarea').on('input', reflowTeam).trigger('input');

   $('.Fixture-form--generate-teams').click(function (e) {
      $.ajax({
         method: 'GET',
         url: '/team/generate',
         data: {
            teams: $('.Fixture-form--teams').val(),
         },
         success: function (res) {
            $('.Team:not(:hidden) textarea').each(function (i) {
               this.value = res.teams[i].join("\n");
               reflowTeam.call(this);
            });
         },
      });
   });

   $('.Fixture-form--generate-draw').click(function (e) {
      var $btn = $(this).addClass('loading');
      $.ajax({
         method: 'GET',
         url: '/fixture/draw',
         data: $btn.closest('form').serialize(),
         success: function (res) {
            $('#draw').html(res);
            $('.Fixture-form--submit').removeClass('hidden');
         },
         complete: function () {
            $btn.removeClass('loading');
         }
      });
   });
});
