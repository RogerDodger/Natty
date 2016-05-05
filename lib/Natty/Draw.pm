package Natty::Draw;
use Mojo::Base 'Exporter';

use Algorithm::Combinatorics qw/permutations/;
use Carp qw/croak/;
use Data::Dump;
use List::Util qw/shuffle max/;
use Mojo::Loader qw/data_section/;
use POSIX qw/ceil floor/;

our @EXPORT_OK = qw/gen_draw/;
our @PRESETS;

sub pairwise;
sub pick;

PARSE_PRESETS: {
   my $size = 3;
   my $data = data_section(__PACKAGE__, 'presets') =~ s/^\s+|\s+$//gr;

   for my $preset (split /\n\n/, $data) {
      my $teams = 0;
      my @picks = map {[
         map {
            $teams = int $_ if $_ > $teams;
            int $_;
         } split /\s+/
      ]} split /\n/, $preset;

      push @PRESETS, {
         _stats(\@picks, $size, $teams),
         teams => $teams,
         matches => \@picks,
      };
   }
}

sub _stats {
   my ($picks, $size, $teams) = @_;

   my %s = (
      games => [ map { 0 } 0..$teams-1 ],
      colors => [
         map {
            [ map { 0 } 0..$size-1 ]
         } 0..$teams-1
      ],
      pairs => [
         map {
            [ map { 0 } 0..$teams-1 ]
         } 0..$teams-1
      ],
      steps => [ map { [] } 0..$teams-1 ],
   );

   for my $g (0..$#$picks) {
      my $pick = $picks->[$g];
      for my $i (0..$size-1) {
         ++$s{games}[ $pick->[$i] ];
         ++$s{colors}[ $pick->[$i] ][$i];
         push $s{steps}[ $pick->[$i] ], $g;
         for my $j ($i+1..$size-1) {
            ++$s{pairs}[ $pick->[$i] ][ $pick->[$j] ];
            ++$s{pairs}[ $pick->[$j] ][ $pick->[$i] ];
         }
      }
   }

   %s;
}

sub gen {
   my %conf = ref $_[0] eq 'HASH' ? %{ +shift } : @_;

   my $size  = 3;
   my $teams = $conf{teams} // 5;
   my $games = $conf{games} // $teams;
   my $tries = $conf{tries} // 5_000;

   croak "Not enough teams (min $size)\n" if $teams < $size;
   croak "Too many teams (max 10)\n" if $teams > 10;

   # In the case of small $teams and large $games, we may have more @matches
   # than $games, in which case we just repeat the list -- it doesn't make
   # sense in this case to care about duplicates
   my @matches;
   while (@matches < $games) {
      # $teams! matches -- okay since if we restrict to less than 10 teams
      @matches = (@matches, permutations [0 .. $teams-1]);
   }

   # Number of games each team plays
   my $topGame = ($size / $teams * $games);
   my $penGame = 1000;

   # Number of times a team gets the same colour
   my $topColor = ($topGame / $size);
   my $penColor = $conf{pen}{color} // 20;

   # Number of times a team plays another team
   my $topPair = (2 * $topGame / ($teams - 1));
   my $penPair = $conf{pen}{pair} // 10;

   # Number of games a team has between games
   my $topStep = $games / $topGame;
   my $penStep = $conf{pen}{step} // 1;

   # Brute force ;3
   # Take random sample of matches and take the best one
   my %best;
   SAMPLE: for (1..$tries) {
      my @picks = pick \@matches, $games;

      if (!%best) {
         %best = (
            pen => { sum => 1e20 },
            matches => \@picks,
         );
         next;
      }

      my %s = _stats(\@picks, $size, $teams);

      my %pen = map { $_ => 0 } qw/game color pair step/;
      for my $i (0..$teams-1) {
         $pen{game}  += $penGame  * abs($topGame  - $s{games}[$i]);
         $pen{color} += $penColor * abs($topColor - $s{colors}[$i][$_]) for 0..$size-1;
         $pen{pair}  += $penPair  * abs($topPair  - $s{pairs}[$i][$_]) for $i+1..$teams-1;
         $pen{step}  += $penStep  * abs($topStep  - $_->[1] - $_->[0]) for pairwise $s{steps}[$i];
      }
      $pen{sum} = List::Util::sum values %pen;

      if ($best{pen}{sum} > $pen{sum}) {
         %best = (
            %s,
            matches => \@picks,
            pen => \%pen,
         );
      }
   }

   for $_ (@{ $best{matches} }) {
      pop @$_ while $#$_ > $size - 1;
   }

   \%best;
}

BEGIN { *gen_draw = \&gen }

sub pairwise {
   my $array = shift;
   my @ret = ();
   for (1..$#$array) {
      push @ret, [ $array->[$_-1], $array->[$_] ];
   }
   @ret;
}


sub pick {
   my ($array, $n) = @_;

   # If array is small enough, do shuffle instead
   if ($#$array / 2 < $n) {
      return +(shuffle @$array)[0..$n-1];
   }

   # This is faster than Fishter-Yates because $array is very big and $n is very
   # small. Technically non-deterministic... but that doesn't actually matter ;p
   my @picks;
   my %picked;
   while ($n-- > 0) {
      my $pick = int rand $#$array;
      redo if $picked{$pick};
      push @picks, $array->[$pick];
      $picked{$pick} = 1;
   }
   return @picks;
}

1;

__DATA__

@@ presets

0 1 2
1 4 3
4 2 0
2 3 1
3 0 4
