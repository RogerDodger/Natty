$(document).ajaxError(function (e, xhr) {
   alert(xhr.status + " " + xhr.statusText);
});

// ===========================================================================
// Player panel buttons
// ===========================================================================

$(document).ready(function () {
   var q = $.when();

   $('.Team-player--swap .fa-exchange').click(function (e) {
      $('.Team-player').removeClass('subbing');
      $(this).closest('.Team-player').addClass('subbing');
   });

   $('.Team-player--swap .fa-close').click(function () {
      $('.Team-player').removeClass('subbing');
   });

   var $players = $('.Player');

   $players.click(function (e) {
      e.preventDefault();
      var $row = $(this);
      var $form = $row.find('form');
      var $player = $('.subbing');

      q = q.then($player.size()
         ? $.ajax({
            method: "POST",
            url: "/team/sub",
            data: {
               team_id: $player.closest('.Team').attr('data-id'),
               oldp_id: $player.attr('data-id'),
               newp_id: $row.attr('data-id'),
            },
            success: function(res) {
               $player.removeClass('subbing');
               $player.attr('data-id', res.id);
               $player.find('.Team-player--name').text(res.tag);
               $player.find('.Team-player--rating').text(res.mu);
            },
         })
         : $.ajax({
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
         var n = this.value;

         $('#draw').empty();
         $('.Fixture-form--submit').addClass('hidden');

         var $presetContainers = $('.Fixture-form--or, .Fixture-form--preset');
         var $presets = $('[name="preset"] option').addClass('hidden');
         var $validPresets = $presets.filter('[data-teams="' + n + '"]').removeClass('hidden');
         if ($validPresets.size()) {
            $validPresets.get(0).selected = true;
            $presetContainers.removeClass('hidden');
         }
         else {
            $presetContainers.addClass('hidden');
         }

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

   var d = function (url) {
      return function (e) {
         var $btn = $(this).addClass('loading');
         $.ajax({
            method: 'GET',
            url: url,
            data: $btn.closest('form').serialize(),
            success: function (res) {
               $('#draw').html(res);
               $('.Fixture-form--submit').removeClass('hidden');
            },
            complete: function () {
               $btn.removeClass('loading');
            }
         });
      };
   };

   $('.Fixture-form--generate-draw').click(d('/fixture/draw-gen'));
   $('.Fixture-form--get-draw').click(d('/fixture/draw-get'));
});
