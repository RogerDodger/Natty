package Natty::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';
use List::Util qw/shuffle/;

sub fetch {
   my $c = shift;
   $c->stash->{game} = $c->db('Game')->find_maybe($c->param('id'));
}

sub create {
   my $c = shift;
   my $mode = $c->db('Mode')->find(1);
   my $games = $c->db('Game');

   my $t = $c->stash->{now}->clone->add(minutes => 2);
   my $last = $games->parse_datetime($games->get_column('scheduled')->max);
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
      $teams[$i % 3]->create_related('team_players', {
         player_id => $ratings[$i]->player_id,
      });
   }

   $c->flash('Game created!');
   $c->redirect_to('games');
}

sub list {
   my $c = shift;

   $c->stash(
      active   => $c->db('Game')->active,
      finished => $c->db('Game')->finished,
   );

   $c->app->log->debug($c->stash->{now});

   $c->render;
}

sub score {
   my $c = shift;
   my $game = $c->stash('game');
   return $c->reply->exception('Game is finalised') if $game->finalised;

   my @teams = $game->teams->all;

   for my $team (@teams) {
      $team->{__score} = $c->param('team' . $team->id)
         or return $c->reply->exception("No score for " . $team->color);
   }

   for my $team (@teams) {
      $team->update({
         score => $team->{__score},
         rank => 1 + grep { $team->{__score} < $_->{__score} } @teams,
      });
   }

   # Set any finished games except this one as finalised
   $c->db('Game')->finalise($game);
   $game->update_ratings;
   $game->update({ finished => Natty::DateTime->now });

   $c->redirect_to('games');
}

1;
