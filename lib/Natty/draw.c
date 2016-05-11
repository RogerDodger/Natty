#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int** make2darray (int x, int y) {
   int** p, i;
   p = (int**) malloc(y * sizeof(int*));
   for (i = 0; i < y; i++) {
      p[i] = (int*) calloc(x, sizeof(int));
   }
   return p;
}

int teams, games, gamesPerTeam,
    **cells, **pairs, *row,
    cy, cx, x, y, i, j, n, s, p, c, r, t,
    minPair, maxPair, maxPairLim,
    minColor, maxColor, maxColorLim;

void unrollpairs () {
   for (p = cx - 1; p >= 0; --p) {
      j = cells[cy][p];
      pairs[i][j] -= 1;
      pairs[j][i] -= 1;
   }
}

void trycell () {
   i = cells[cy][cx];

   if (i != 0) {
      unrollpairs();
   }

   for (i = i + 1; i <= teams; ++i, ++r) {
      cells[cy][cx] = i;

      // Check i is not already in this row
      for (x = cx - 1; x >= 0; --x) {
         if (cells[cy][x] == i) {
            goto next;
         }
      }

#ifdef NOREP
      // Check i is not in the previous row
      if (cy != 0) {
         for (x = 2; x >= 0; --x) {
            if (cells[cy-1][x] == i) {
               goto next;
            }
         }
      }
#endif

      // Check i has not played this colour too many times
      if (maxColorLim == 0) {
         n = minColor - 1;
         for (y = 0; y < cy; ++y) {
            if (cells[y][cx] == i && --n < 0) {
               goto next;
            }
         }
      }
      else {
         // TODO
         fprintf(stderr, "Not implemented\n");
         exit(2);
      }

      // Check i has not played these opponents too many times
      for (p = cx - 1; p >= 0; --p) {
         j = cells[cy][p];
         pairs[i][j] += 1;
         pairs[j][i] += 1;
      }

      if (maxPairLim == 0) {
         for (p = cx - 1; p >= 0; --p) {
            n = minPair - 1;
            j = cells[cy][p];
            for (y = 0; y < cy; ++y) {
               s = 0;
               for (x = 0; x < 3; ++x) {
                  c = cells[y][x];
                  if (c == i || c == j) {
                     if (s && --n < 0) {
                        unrollpairs();
                        goto next;
                     }
                     s = 1;
                  }
               }
            }
         }
      }
      else {
         for (p = cx; p >= 0; --p) {
            n = maxPairLim;
            j = cells[cy][p];
            row = pairs[j];
            for (t = 1; t <= teams; ++t) {
               if (row[t] > maxPair || row[t] == maxPair && --n < 0) {
                  unrollpairs();
                  goto next;
               }
            }
         }
      }

      // Constraints are satisfied
      break;

      next:;
   }

   cells[cy][cx] = i > teams ? 0 : i;
}

int main (int argc, char **argv) {
   teams = 7;
   if (argc > 1) teams = atoi(argv[1]);
   games = teams;

   // Currently games = teams, so this isn't a problem
   if (3 * games % teams) {
      fprintf(stderr, "No possible fixture with balanced game count\n");
      exit(1);
   }
   gamesPerTeam = (3 * games) / teams;

   // If minColor == maxColor, teams play each color exactly minColor times.
   // Otherwise, they play maxColorLim colors maxColor times, and the rest of
   // the colors minColor times
   minColor = games / teams;
   maxColorLim = games % teams;
   maxColor = minColor + (maxColorLim != 0);

   // Same as above
   minPair = (2 * gamesPerTeam) / (teams - 1);
   maxPairLim = (2 * gamesPerTeam) % (teams - 1);
   maxPair = minPair + (maxPairLim != 0);

   // Cells are zeroed. To disambiguate an undefined cell from team 0, the
   // teams are 1-indexed. A cell of 0 is an unset cell.
   cells = make2darray(3, games);
   pairs = make2darray(teams + 1, teams + 1);

   // Backtracking algorithm
   for (cy = 0; cy < games; ++cy) {
      cx = 0;
      while (cx < 3) {
         trycell();
         if (cells[cy][cx]) {
            ++cx;
         }
         else {
            // No possible value for this cell, backtrack
            if (cx != 0) {
               --cx;
            }
            else if (cy == 0) {
               printf("%d iters\n\n", r);
               fprintf(stderr, "No solution\n");
               exit(0);
            }
            else {
               --cy;
               cx = 2;
            }
         }
      }
   }

   printf("%d iters\n\n", r);

   // Output fixture
   for (cy = 0; cy < games; ++cy) {
      row = cells[cy];
      for (cx = 0; cx < 3; ++cx) {
         printf("%d ", row[cx] - 1);
      }
      printf("\n");
   }
   printf("\n");
   for (cy = 1; cy <= teams; ++cy) {
      row = pairs[cy];
      for (cx = 1; cx <= teams; ++cx) {
         printf("%d ", row[cx]);
      }
      printf("\n");
   }

   return 0;
}
