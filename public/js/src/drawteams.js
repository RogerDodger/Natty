// ===========================================================================
// Team balancing stuff
// ===========================================================================

$(document).ready(function () {
   var $textarea = $('.TB--Input');
   var $add = $('.TB--Add');
   var $balance = $('.TB--Balance');
   var $clear = $('.TB--Clear');
   var $teams = $('.TB--Teams');
   var $cap = $('.TB--Cap');
   var sumCap = false;

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

      if (sumCap) {
         // The team's rating is the sum of its 5 best player's ratings, since
         // that is the strongest the team can be. Given that teams with more
         // than 5 players probably have 6 or 7, its quickest to simply
         // subtract the minimums off.

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

      if (teams.length) {
         $clear.add($cap).removeClass('hidden');
      }
      else {
         $clear.add($cap).addClass('hidden');
      }
   };

   var saveState = function () {
      if (typeof localStorage === 'undefined') {
         return;
      }

      var shallow = teams.map(function (e) {
         return {
            sum: e.sum,
            players: e.players.map(function (p) {
               return {
                  name: p.name,
                  rating: p.rating,
                  locked: p.locked
               };
            })
         };
      })

      localStorage.setItem('balancerteams', JSON.stringify(shallow));
   };

   var loadState = function () {
      if (typeof localStorage === 'undefined') {
         return;
      }

      if (localStorage.getItem('balancerteams')) {
         teams = JSON.parse(localStorage.getItem('balancerteams'));
      }

      redrawTeams();
   };

   loadState();

   $cap.find('input').click(function () {
      sumCap = this.checked;
      recalcSums();
   });

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
      saveState();
      redrawTeams();
   });

   $teams.on('click', '.TB--TP--Lock', function (e) {
      var $player = $(e.target).closest('.TB--Team--Player');
      var player = $player.get(0).pobj;
      var icon = $player.find('.TB--TP--Lock .icon').get(0);

      player.locked = !player.locked;
      icon.innerHTML = player.locked ? 'lock' : 'lock_open';
      saveState();
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
      toastr.warning(
         "Player removed: " + el.pobj.name + " " + el.pobj.rating);
      removePlayer(el, source);
      saveState();
   });

   $clear.on('click', function () {
      teams = [];
      saveState();
      redrawTeams();
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

      for (i = 0; i < 50000; ++i) {
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

      saveState();
      redrawTeams();
   });
});
