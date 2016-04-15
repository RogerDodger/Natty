package Natty::Draw;
use Mojo::Base 'Exporter';

use Algorithm::Combinatorics qw/permutations/;
use Carp qw/croak/;
use Data::Dump;
use List::Util qw/max/;
use POSIX qw/ceil floor/;

our @EXPORT_OK = qw/get_draw/;

sub pairwise;
sub pick;

sub get {
   my $conf = shift // {};

   # Return values
   my @best;
   my $stats = shift // {};

   my $size  = 3;
   my $teams = $conf->{teams} // 5;
   my $games = $conf->{games} // $teams;
   my $tries = $conf->{tries} // 20_000;

   croak "Not enough teams (min $size)\n" if $teams < $size;
   croak "Too many teams (max 10)\n" if $teams > 10;

   # Number of games each team plays
   my $topGame = ($size / $teams * $games);
   my $penGame = 400;

   # Number of times a team gets the same colour
   my $topColor = ($topGame / $size);
   my $penColor = 20;

   # Number of times a team plays another team
   my $topPair = (2 * $topGame / ($teams - 1));
   my $penPair = 10;

   # Number of games a team has between games
   my $topStep = 1 + ($games - $topGame) / $topGame;
   my $penStep = 1;

   # n! matches -- okay since if we restrict to less than 10 teams
   my @matches = permutations [0 .. $teams-1];

   # Brute force ;3
   # Take random sample of matches and take the best one

   SAMPLE: for (1..$tries) {
      my @picks = pick \@matches, $games;

      if (!@best) {
         @best = \@picks;
         %$stats = ( pen => { sum => 1e20 });
         next;
      }

      my @games = map { 0 } 0..$teams-1;
      my @colors = map {
            [ map { 0 } 0..$size-1 ]
         } 0..$teams-1;
      my @pairs = map {
            [ map { 0 } 0..$teams-1 ]
         } 0..$teams-1;
      my @steps = map { [] } 0..$teams-1;

      for my $g (0..$#picks) {
         my $pick = $picks[$g];
         for my $i (0..$size-1) {
            ++$games[ $pick->[$i] ];
            ++$colors[ $pick->[$i] ][$i];
            push $steps[ $pick->[$i] ], $g;
            for my $j ($i+1..$size-1) {
               ++$pairs[ $pick->[$i] ][ $pick->[$j] ];
               ++$pairs[ $pick->[$j] ][ $pick->[$i] ];
            }
         }
      }

      my %pen = map { $_ => 0 } qw/game color pair step/;
      for my $i (0..$teams-1) {
         $pen{game}  += $penGame  * abs($topGame  - $games[$i]);
         $pen{color} += $penColor * abs($topColor - $colors[$i][$_]) for 0..$size-1;
         $pen{pair}  += $penPair  * abs($topPair  - $pairs[$i][$_]) for $i+1..$teams-1;
         $pen{step}  += $penStep  * abs($topStep  - $_->[1] - $_->[0]) for pairwise $steps[$i];
      }
      $pen{sum} = List::Util::sum values %pen;

      if ($stats->{pen}{sum} > $pen{sum}) {
         @best = @picks;
         %$stats = (
            pen => \%pen,
            colors => \@colors,
            pairs => \@pairs,
            steps => \@steps,
            games => \@games,
         );
      }
   }

   for $_ (@best) {
      pop @$_ while $#$_ > $size - 1;
   }

   \@best;
}

BEGIN { *get_draw = \&get }

sub pairwise {
   my $array = shift;
   my @ret = ();
   for (1..$#$array) {
      push @ret, [ $array->[$_-1], $array->[$_] ];
   }
   @ret;
}

# It's not actually important to avoid duplicates since they are both unlikely
# and will just fail the constraints in the main loop much quicker than we can
# guarantee no duplicates
sub pick {
   my ($array, $n) = @_;

   my @picks = map $array->[int rand $#$array], 1..$n;
   return @picks;
}

1;
