"use strict";

/* public/js/src/lib/array.js */;
(function () {
   // https://github.com/mout/mout/blob/master/src/array/sort.js
   function mergeSort(arr, compareFn) {
      if (arr == null) {
         return [];
      } else if (arr.length < 2) {
         return arr;
      }

      if (compareFn == null) {
         compareFn = defaultCompare;
      }

      var mid, left, right;

      mid   = ~~(arr.length / 2);
      left  = mergeSort( arr.slice(0, mid), compareFn );
      right = mergeSort( arr.slice(mid, arr.length), compareFn );

      return merge(left, right, compareFn);
   }

   function defaultCompare(a, b) {
      return a < b ? -1 : (a > b? 1 : 0);
   }

   function merge(left, right, compareFn) {
      var result = [];

      while (left.length && right.length) {
         if (compareFn(left[0], right[0]) <= 0) {
            // if 0 it should preserve same order (stable)
            result.push(left.shift());
         } else {
            result.push(right.shift());
         }
      }

      if (left.length) {
         result.push.apply(result, left);
      }

      if (right.length) {
         result.push.apply(result, right);
      }

      return result;
   }

   Array.prototype.mergesort = function (compareFn) {
      return mergeSort(this, compareFn);
   };
})();

/* public/js/src/lib/date.js */;
Date.prototype.getShortMonth = function () {
   return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][this.getMonth()];
};

/* public/js/src/lib/element.js */;
if (!('remove' in Element.prototype)) {
    Element.prototype.remove = function() {
        if (this.parentNode) {
            this.parentNode.removeChild(this);
        }
    };
}

/* public/js/src/lib/number.js */;
Number.prototype.zeropad = function(n) {
   var str = "" + this;
   var len = n - str.length;
   var pad = "";
   while (len-- > 0) {
      pad += "0";
   }
   return pad + str;
};

/* public/js/src/lib/strings.js */;
String.prototype.zeropad = function (n) {
   var s = this;
   var l = n - s.length;
   while (l-- > 0) {
      s = s + '0';
   }
   return s;
}

/* public/js/src/core.js */;
$(document).ajaxError(function (e, xhr) {
   if (typeof xhr.responseText === "string" && xhr.responseText.length) {
      toastr.error(xhr.responseText);
   } else {
      toastr.error(xhr.status + " " + xhr.statusText);
   }
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

      q = q.then($player.length
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
   if (!$form.length) {
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
         if ($validPresets.length) {
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

/* public/js/src/draw.js */;
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

/* public/js/src/drawteams.js */;
// ===========================================================================
// Team balancing stuff
// ===========================================================================

$(document).ready(function () {
   var $textarea = $('.TB--Input');
   var $add = $('.TB--Add');
   var $balance = $('.TB--Balance');
   var $teams = $('.TB--Teams');

   if (!$textarea.length) {
      return;
   }

   var containers = $('.TB--Team').get();

   var drake = dragula(containers, {
      direction: 'vertical',
      removeOnSpill: true,
      moves: function (el, source, handle, sibling) {
         return el.classList.contains('TB--Team--Player');
      },
      accepts: function (el, target, source, sibling) {
         return sibling === null || !sibling.classList.contains('TB--Team--Sum');
      }
   });

   var teams = [];

   var recalcSum = function (team, dom_) {
      var dom = typeof dom_ !== 'undefined' ? dom_ : true;
      var ratings = team.players.map(function (e) { return e.rating; });

      team.sum = 0;
      ratings.forEach(function (e) {
         team.sum += e;
      });

      // The team's rating is the sum of its 5 best player's ratings, since
      // that is the strongest the team can be. Given that teams with more
      // than 5 players probably have 6 or 7, its quickest to simply subtract
      // the minimums off.
      //
      // Algorithm resembles insertion sort.
      for (var x = 5; x < ratings.length; ++x) {
         var min = 0;
         for (var i = 1; i < ratings.length; ++i) {
            if (ratings[i] < ratings[min]) {
               min = i;
            }
         }
         team.sum -= ratings[min];
         ratings[min] = +Infinity;
      }

      if (dom && 'el' in team) {
         team.el.firstChild.innerHTML = team.sum.toFixed(2).zeropad(4);
      }
   }

   var recalcSums = function () {
      teams.forEach(recalcSum);
   };

   var redrawTeams = function () {
      var teamsel = $teams.get(0);
      teamsel.innerHTML = '';
      containers.length = 0;

      for (var i = 0; i < teams.length; ++i) {
         var team = teams[i];
         var players = team.players;

         var teamel = document.createElement('div');
         teamel.className = 'TB--Team';
         containers.push(teamel);

         var sum = document.createElement('div');
         sum.className = 'TB--Team--Sum';
         sum.innerHTML = team.sum.toFixed(2).zeropad(4);
         teamel.insertAdjacentElement('beforeend', sum);

         for (var j = 0; j < players.length; ++j) {
            var playerel = document.createElement('div');
            playerel.className = 'TB--Team--Player';

            var lock = document.createElement('div');
            lock.className = 'TB--TP--Lock';
            lock.insertAdjacentHTML('afterbegin',
               '<i class="icon">' + (players[j].locked ? 'lock' : 'lock_open') + '</i>');

            var name = document.createElement('div');
            name.className = 'TB--TP--Name';
            name.innerHTML = players[j].name;

            var score = document.createElement('div');
            score.className = 'TB--TP--Rating';
            score.innerHTML = players[j].rating.toFixed(2).zeropad(4);

            [lock, name, score].forEach(function (e) {
               playerel.insertAdjacentElement('beforeend', e);
            });

            teamel.insertAdjacentElement('beforeend', playerel);

            playerel.pobj = players[j];
            players[j].el = playerel;
         }

         teamel.tobj = team;
         team.el = teamel;

         teamsel.insertAdjacentElement('beforeend', teamel);
      }

      if (teams.length >= 2) {
         $balance.removeClass('hidden');
      }
      else {
         $balance.addClass('hidden');
      }
   };

   $add.click(function () {
      var i = 0, matches;

      $textarea.val().split('\n').forEach(function (line) {
         if (matches = line.match(/^(.+) (\d?.\d+)/)) {
            while (i < teams.length && teams[i].players.length >= 5) {
               i++;
            }

            if (i == teams.length) {
               teams.push({ sum: 0, players: [] });
            }

            teams[i].players.push({
               rating: parseFloat(matches[2]),
               name: matches[1],
               locked: false
            });
         }
      });
      $textarea.val('');

      recalcSums();
      redrawTeams();
   });

   $teams.on('click', '.TB--TP--Lock', function (e) {
      var $player = $(e.target).closest('.TB--Team--Player');
      var player = $player.get(0).pobj;
      var icon = $player.find('.TB--TP--Lock .icon').get(0);

      player.locked = !player.locked;
      icon.innerHTML = player.locked ? 'lock' : 'lock_open';
   });

   var removePlayer = function (el, source) {
      var splayers = source.tobj.players;
      for (var i = 0; i < splayers.length; ++i) {
         if (splayers[i] === el.pobj) {
            splayers.splice(i, 1);
         }
      }

      if (splayers.length == 0) {
         teams = teams.filter(function (t) {
            return t.el !== source;
         });
         source.remove();
      }

      recalcSum(source.tobj);
   }

   drake.on('drop', function (el, target, source, sibling) {
      // Pop player from old team
      removePlayer(el, source);

      // Push player to new team
      var tplayers = target.getElementsByClassName('TB--Team--Player');
      for (var i = 0; i < tplayers.length; ++i) {
         if (tplayers[i] === el) {
            target.tobj.players.splice(i, 0, el.pobj);
         }
      }

      recalcSum(target.tobj);
   });

   drake.on('remove', function (el, container, source) {
      removePlayer(el, source);
   });

   $balance.on('click', function () {
      // System heat is the variance in team sums
      var currHeat = function () {
         var avg = 0;
         teams.forEach(function (t) {
            avg += t.sum;
         });
         avg /= teams.length;

         var h = 0;
         teams.forEach(function (t) {
            h += Math.pow(Math.abs(t.sum - avg), 2);
         });

         return h / teams.length;
      };

      // Because we have the option of locking cells, we have an exhaustive
      // list of unlocked cells from which we randomly index. This also cuts
      // down on the number of Math.random() calls in the main loop.
      var cells = [];
      teams.forEach(function (t, i) {
         t.players.forEach(function (p, j) {
            if (!p.locked) {
               cells.push({ y: i, x: j });
            }
         });
      })

      var cellswap = function (c1, c2) {
         var p1 = teams[c1.y].players[c1.x],
             p2 = teams[c2.y].players[c2.x];

         teams[c1.y].players[c1.x] = p2;
         teams[c2.y].players[c2.x] = p1;

         recalcSum(teams[c1.y], false);
         recalcSum(teams[c2.y], false);
      }

      var best = currHeat(),
          cell1, cell2, heat, i, fails = [], j = 1, swaps = 0;

      var unrollfails = function () {
         while (fails.length) {
            var fail = fails.pop();
            cellswap(fail[0], fail[1]);
         }
      }

      for (i = 0; i < 10000; ++i) {
         cell1 = cells[Math.floor(Math.random() * cells.length)];
         cell2 = cells[Math.floor(Math.random() * cells.length)];

         // Moving players between teams does nothing
         if (cell1.y === cell2.y) {
            continue;
         }

         cellswap(cell1, cell2);

         heat = currHeat();
         if (heat < best) {
            swaps++;
            best = heat;
            fails = [];
            j = 1;
         }
         else {
            fails.push([ cell1, cell2 ]);
            if (fails.length >= j) {
               unrollfails();
               j = j % 20 + 1;
            }
         }
      }
      unrollfails();

      // Order players in each team
      //
      // Can't use builtin Array#sort we require a stable sort
      teams.forEach(function (team) {
         team.players = team.players.mergesort(function (a, b) {
            if (a.locked || b.locked) {
               return 0;
            }
            else if (a.rating > b.rating) {
               return -1;
            }
            else if (a.rating == b.rating) {
               return 0
            }
            else {
               return 1;
            }
         });
      });

      redrawTeams();
   });
});

