#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define min(a,b) (a) > (b) ? (b) : (a)

int** make2darray (int x, int y) {
   int** p, i;
   p = (int**) malloc(y * sizeof(int*));
   for (i = 0; i < y; i++) {
      p[i] = (int*) calloc(x, sizeof(int));
   }
   return p;
}

int teams, opps, games, gamesPerTeam,
    **cells, **pairs, **colors, *row,
    cols, height, printed,
    cy, cx, x, y, c, i, j, k, n, s, p, t,
    minPair, maxPair, maxPairLim,
    minColor, maxColor, maxColorLim;

long long int r;

void printgrid() {
   if (printed) {
      printf("\033[%dA", height + 2);
   }
   else {
      printed = 1;
   }
   // usleep(300 * 1000);

   printf("%lli iters\n\n", r);
   for (y = 0; y < height; ++y) {
      for (c = 0; c < cols && y + c*height < games; ++c) {
         row = cells[y + c*height];
         for (x = 0; x < 3; ++x) {
            printf("%02d ", row[x]);
         }
         printf("  ");
      }
      printf("\n");
   }
}

void trycell () {
   i = cells[cy][cx];
   k = (cy + cx + (cx == 2)) % teams;
   if (!k) k = teams;

   if (i == 0) {
      i = 1 + k % teams;
   }
   else {
      goto unrollpairs;
   }

   do {
      cells[cy][cx] = i;

      if ((++r & 65535) == 65535) {
         printgrid();
      }

      // Check i is not already in this row
      for (x = cx - 1; x >= 0; --x) {
         if (cells[cy][x] == i) {
            goto next;
         }
      }

      // Check i has not played this colour too many times
      colors[i][cx]++;

      if (maxColorLim == 0) {
         if (colors[i][cx] > minColor) {
            goto unrollcolors;
         }
      }
      else {
         n = maxColorLim;
         row = colors[i];
         for (t = 0; t < 3; ++t) {
            if (row[t] > maxColor || (row[t] == maxColor && --n < 0)) {
               goto unrollcolors;
            }
         }
      }

      // Check i has not played these opponents too many times
      for (p = cx - 1; p >= 0; --p) {
         j = cells[cy][p];
         pairs[i][j] += 1;
         pairs[j][i] += 1;
      }

      if (maxPairLim == 0) {
         for (p = cx - 1; p >= 0; --p) {
            j = cells[cy][p];
            if (pairs[i][j] > minPair) {
               goto unrollpairs;
            }
         }
      }
      else {
         for (p = cx; p >= 0; --p) {
            n = maxPairLim;
            j = cells[cy][p];
            row = pairs[j];
            for (t = 1; t <= teams; ++t) {
               if (row[t] > maxPair || (row[t] == maxPair && --n < 0)) {
                  goto unrollpairs;
               }
            }
         }
      }

      // Constraints are satisfied
      cells[cy][cx] = i;
      return;

      unrollpairs:;
         for (p = cx - 1; p >= 0; --p) {
            j = cells[cy][p];
            pairs[i][j] -= 1;
            pairs[j][i] -= 1;
         }

      unrollcolors:;
         colors[i][cx]--;

      next:;
         // Tried everything, backtrack
         if (i == k) {
            cells[cy][cx] = 0;
            return;
         }

         i = 1 + i % teams;
   } while (1);
}

int main (int argc, char **argv) {
   teams = 13;
   if (argc > 1) teams = atoi(argv[1]);

   opps = teams - 1;
   gamesPerTeam = opps % 2 ? opps : opps / 2;
   games = gamesPerTeam * teams / 3;

   if (teams == 5) {
      gamesPerTeam *= 2;
      games *= 2;
   }

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

   printf("games: %d per team, %d total\n", gamesPerTeam, games);
   printf("colors: %d + %d\n", minColor, maxColorLim);
   printf("pairs: %d + %d\n\n", minPair, maxPairLim);

   // Cells are zeroed. To disambiguate an undefined cell from team 0, the
   // teams are 1-indexed. A cell of 0 is an unset cell.
   cells = make2darray(3, games);
   pairs = make2darray(teams + 1, teams + 1);
   colors = make2darray(3, teams + 1);

   height = min(games, 16);
   cols = 1 + (games - 1) / height;

   // Backtracking algorithm
   for (cx = 0; cx < 3; ++cx) {
      cy = 0;
      while (cy < games) {
         trycell();
         if (cells[cy][cx]) {
            ++cy;
         }
         // No possible value for this cell, backtrack
         else {
            if (cy != 0) {
               --cy;
            }
            else if (cx != 0) {
               --cx;
               cy = games - 1;
            }
            // Can't backtrack -- no solution
            else {
               printf("%lli iters\n\n", r);
               fprintf(stderr, "No solution\n");
               exit(0);
            }
         }
      }
   }

   printgrid();
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
