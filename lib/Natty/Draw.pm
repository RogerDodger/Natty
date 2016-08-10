package Natty::Draw;
use Natty::Base -base;

use Carp qw/croak/;
use List::Util qw/shuffle max/;
use Mojo::Loader qw/data_section/;
use Mojo::Util qw/md5_sum/;
use POSIX qw/ceil floor/;

our @PRESETS;
my @COLORS = qw/red blue green orange cyan purple yellow pink/;

PRESETS: {
   my $data = data_section(__PACKAGE__, 'presets') =~ s/^\s+|\s+$//gr;
   for my $preset (split /\n{2,}/, $data) {
      push @PRESETS, __PACKAGE__->parse($preset);
   }
}

sub parse ($class, $data) {
   my (%teams, @draw);
   for my $line (split /(?:;\s*)|\n/, $data) {
      my %g;
      push @draw, my $game = [];
      for (split /\s+/, $line =~ s/^\s+|\s+$//gr) {
         die "Team $_ is in game " . +@draw . " twice\n" if $g{$_};
         die "'$_' is not an integer\n" if $_ =~ /\D/;
         $g{$_} = $teams{$_} = 1;
         push @$game, int $_;
      }
      die "Game " . +@draw . " has too few teams\n" if @$game <= 1;
   }
   die "Draw has no games\n" if !@draw;

   # Coerce teams such that they're numbered from 0..n-1; mostly needed when
   # input has a 1-indexed numbering
   my @teams = sort { $a <=> $b } keys %teams;
   my %map = map { $teams[$_] => $_ } 0..$#teams;
   for my $game (@draw) {
      for my $team (@$game) {
         $team = $map{$team};
      }
   }

   return $class->new(matches => \@draw, teams => scalar @teams);
}

sub code ($self) {
   $self->{code} //=
      join '; ', map {
         join ' ', map {
            sprintf "%d", $_ + 1
         } @$_
      } $self->matches->@*;
}

sub colors ($self) {
   $self->{colors} //= 1 + max map $#$_, $self->matches->@*;
}

sub games ($self) {
   $self->{games} //= scalar $self->matches->@*;
}

sub id ($self) {
   $self->{id} //= substr md5_sum($self->code), 0, 6;
}

sub matches ($self) { $self->{matches} }

sub pairs ($self) {
   $self->{pairs} //= do {
      my @pairs = map [ (0) x $self->teams ], 1..$self->teams;

      for my $match ($self->matches->@*) {
         my $i = 0;
         for my $x ($match->@*) {
            $i++;
            for my $y ($match->@[$i..$#$match]) {
               $pairs[$x][$y] += 1;
               $pairs[$y][$x] += 1;
            }
         }
      }

      \@pairs;
   };
}

sub teams ($self) { $self->{teams} }

sub timeline ($self) {
   $self->{timeline} //= [
      map {
         my $round = $_;
         my %map = @$round <= 8
            ? map { $round->[$_] => $COLORS[$_] } 0..$#$round
            : map { $round->[$_] => 'grey' } 0..$#$round;
         \%map;
      } $self->matches->@*
   ];
}

1;

__DATA__

@@ presets

1 2 3; 3 1 2; 2 3 1

1 2 3; 2 1 4; 3 4 1; 4 3 2

1 2 3; 2 5 4; 5 3 1; 3 4 2; 4 1 5

1 2 3; 3 4 5; 5 6 1; 2 1 4; 4 3 6; 6 5 2

1 2 3; 2 4 5; 3 5 6; 4 3 7; 5 7 1; 6 1 4; 7 6 2
