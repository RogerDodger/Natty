package Natty::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';
use List::Util qw/shuffle/;

sub create {
   my $c = shift;
   my $mode = $c->db('Mode')->find(1);

   my $t = $c->config->{now}->clone->add(minutes => 2);
   my $last = $c->db('Game')->get_column('scheduled')->max;
   if ($last) {
      $last = $last->clone->add(minutes => 20);
      $t = $last if $last > $t;
   }

   my @ratings = shuffle $mode->ratings->all;
   return $c->reply->exception("Not enough players") if @ratings < 15;

   my $game = $mode->create_related('games', { scheduled => $t });
   my @teams = map {
                  $game->create_related('teams', { color => $_ })
               } qw/blue red green/;

   for my $i (0..14) {
      $teams[$i % 3]->create_related('players', {
         player_id => $ratings[$i]->player_id,
      });
   }

   $c->flash('Game created!');
   $c->redirect_to('players');
}

sub list {
   my $c = shift;

   $c->stash(
      games => $c->db('Game')->today,
   );

   $c->render;
}

1;
