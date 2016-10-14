// ===========================================================================
// Draw list filters and breakdown
// ===========================================================================

$(document).ready(function () {
   var $form = $('.Draw-list--filters');
   if (!$form.length) return;

   var $teams = $form.find('[name="teams"]');

   $form.change('select', function () {
         $('.Draw.preset')
            .addClass('hidden')
            .filter('[data-teams="' + $teams.val() + '"]')
            .removeClass("hidden");
      })
      .trigger('change');

   $('.Draw-expand').click(function () {
      var $draw = $(this).closest('.Draw');
      var $breakdown = $draw.find('.Draw-breakdown');
      var $spinner = $draw.find('.spinner');
      var $icon = $(this);

      if (!$spinner.hasClass('hidden')) return;

      if ($icon.text() == 'add') {
         $icon.text('hourglass_empty');
         $spinner.removeClass('hidden');

         $.ajax({
            url: '/draw/parse',
            method: 'GET',
            data: { draw: $draw.find('.Draw-code').attr('data-code') },
            success: function (res) {
               $breakdown.html(res);
            },
            complete: function (xhr, status) {
               $icon.text(status == "error" ? 'add' : 'remove');
               $spinner.addClass('hidden');
            }
         });
      }
      else {
         $icon.text('add');
         $breakdown.empty();
      }
   });

   // Remove non-digit non-semicolons from the input field
   $('.Draw-manual--field').on('input', function () {
      this.value = this.value.replace(/[^\d; ]/, '');
   });

   $('.Draw-reload').click(function () {
      var $draw = $(this).closest('.Draw');
      var $breakdown = $draw.find('.Draw-breakdown');
      var $spinner = $draw.find('.spinner');

      $breakdown.empty();
      $spinner.removeClass('hidden');
      $.ajax({
         url: '/draw/parse',
         method: 'GET',
         data: { draw: $draw.find('.Draw-manual--field').val() },
         success: function (res) {
            $breakdown.html(res);
         },
         complete: function () {
            $spinner.addClass('hidden');
         }
      });
   });
});

// ===========================================================================
// Draw generator
// ===========================================================================

$(document).ready(function () {
   var $form = $('.Draw-generator');
   if (!$form.length) return;

   var $teams = $form.find("[name='gen-teams']");
   var $games = $form.find("[name='gen-games']");

   var $code      = $form.find('.Draw-generator--code');
   var $draw      = $form.find('.Draw');
   var $breakdown = $draw.find('.Draw-breakdown');
   var $spinner   = $draw.find('.spinner');
   var $setup     = $('.Draw-generator--setup');
   var $go        = $('.Draw-generator--go');

   var teams, games, gamesPerTeam, grid, score, fails;
   var goInterval;

   var loadBreakdown = function () {
      $spinner.removeClass('hidden');
      $breakdown.empty();
      return $.ajax({
         url: '/draw/parse',
         method: 'GET',
         data: { draw: $code.text() },
         success: function (res) { $breakdown.html(res); },
         complete: function () { $spinner.addClass('hidden') }
      });
   };


   var outputCode = function () {
      var code = "", row, i, j;

      if (typeof grid === "undefined") return;

      for (i = 0; i < grid.length; ++i) {
         row = grid[i];
         for (j = 0; j < row.length; ++j) {
            code += " " + (row[j] + 1);
         }
         if (i != grid.length - 1) code += ";";
      }

      $code.text(code.trim());
   }

   $setup.click(function () {
      var i;

      if (!$form.get(0).checkValidity()) {
         return toastr.error("Invalid parameters");
      }

      teams = $teams.val();
      games = $games.val();
      gamesPerTeam = games * 3 / teams;

      fails = 0;
      score = Infinity;

      grid = [];
      for (i = 0; i < games; ++i) {
         grid.push([
            (i * 3 + 0) % teams,
            (i * 3 + 1) % teams,
            (i * 3 + 2) % teams
         ]);
      }
      outputCode();
      loadBreakdown();
   });

   var calcPlays = function () {
      var i, j, plays = new Array(teams);
      for (i = 0; i < teams; ++i) {
         plays[i] = new Array(teams);
         for (j = 0; j < teams; ++j) {
            plays[i][j] = 0;
         }
      }

      grid.forEach(function (game) {
         for (i = 0; i < 3; ++i) {
            for (j = i + 1; j < 3; ++j) {
               ++plays[ game[i] ][ game[j] ];
               ++plays[ game[j] ][ game[i] ];
            }
         }
      });

      return plays;
   }

   var scoreTimeOnSite = function () {
      return 0;
      // var t, i, j, target = 2*gamesPerTeam - 1, score = 0;

      // for (t = 0; t < teams; ++t) {
      //    for (i = 0; grid[i].indexOf(t) === -1; ++i);
      //    for (j = grid.length - 1; grid[j].indexOf(t) === -1; --j);
      //    score += Math.pow(Math.max(j - i - target, 0), 2);
      // }

      // return score;
   };

   var scoreRobin = function () {
      var i, j, score = 0,
         avgPlays = gamesPerTeam * 2 / (teams - 1),
         plays = calcPlays();

      for (i = 0; i < teams; ++i) {
         for (j = 1; j < teams; ++j) {
            if (!plays[i][j]) {
               score += 100;
            }
            else {
               score += Math.pow(plays[i][j] - avgPlays, 4) * 40;
            }
         }
      }

      return score;
   };

   // var scoreCascade = function () {

   // };

   var goTick = function () {
      var i, x1, x2, y, team1, team2, newScore,
         copy = grid.map(function (row) {
            return [row[0], row[1], row[2]];
         });

      for (i = Math.min(fails, 96); i < 100; ++i) {
         // We only swap teams into games that they aren't already in, and we
         // only swap teams of the same colour
         do {
            y = Math.floor(Math.random() * 3);
            x1 = Math.floor(Math.random() * grid.length);
            x2 = Math.floor(Math.random() * grid.length);
            team1 = grid[x1][y];
            team2 = grid[x2][y];
         } while (grid[x1].indexOf(team2) !== -1 || grid[x2].indexOf(team1) !== -1);
         grid[x1][y] = team2;
         grid[x2][y] = team1;
      }

      newScore = scoreRobin() + scoreTimeOnSite();
      if (newScore < score) {
         console.log(newScore + " < " + score);
         fails = 0;
         score = newScore;
         outputCode();
      }
      else {
         ++fails;
         if (fails > 250) fails = 50;
         grid = copy;
      }
   };

   $go.click(function () {
      if (typeof grid === "undefined") {
         toastr.error("Grid not setup");
         return;
      }

      if ($go.text() === "Go") {
         $go.text("Stop");
         $setup.prop('disabled', true);
         $breakdown.empty();
         $spinner.removeClass('hidden');
         goInterval = setInterval(goTick, 0);
      }
      else if ($go.text() === "Stop") {
         $go.text("Stopping");
         clearInterval(goInterval);
         loadBreakdown().then(function () {
            $go.text("Go");
            $setup.prop('disabled', false);
         });
      }
   });
});
