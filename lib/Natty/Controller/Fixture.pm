package Natty::Controller::Fixture;
use Mojo::Base 'Mojolicious::Controller';

use DateTime::Format::RFC3339;
use List::Util qw/min shuffle/;
use Mojo::JSON qw/encode_json/;
use Mojo::Util qw/steady_time b64_encode/;
use Natty::Draw qw/gen_draw/;
use feature qw/fc/;

sub fetch {
   my $c = shift;
   $c->stash->{fixture} = $c->db('Fixture')->find_maybe($c->param('fid'));
}

sub add {
   my $c = shift;
   my $players = $c->db('Player');

   my $gamelen = $c->parami('gamelen') // 15;

   my $t = DateTime::Format::RFC3339->parse_datetime($c->paramo('start')) and
   my $teams = $c->parami('teams') and
   my $games = $c->parami('games') and
   my $mode = $c->db('Mode')->find_maybe($c->param('mode'))
      or return $c->reply->exception("Bad input");

   my $draw64 = $c->config->{drawCache}->get($c->paramo('draw'))
      or return $c->stash->{error_msg} = 'Draw expired';

   my @teams = @{ $c->every_param('team') };
   for (0..$teams-1) {
      my $str = $teams[$_] or return $c->stash->{error_msg} = "Team $_ is empty!";
      my $team = $teams[$_] = [];
      for (split /\s+/, $str) {
         my $player = $players->search({ tag_normalised => fc $_ })->first
            or return $c->stash->{error_msg} = "Player $_ not found!";

         push $team, $player;
      }
   }

   # The @teams array might have some dangling empty string params
   @teams = @teams[0..$teams-1];

   my $fixture = $c->db('Fixture')->create({
      mode_id => $mode->id,
      draw => $draw64,
      start => $t,
   });

   my $draw = $c->db('Fixture')->find($fixture->id)->draw;
   my $teamSize = min map { scalar @$_ } @teams;

   my @tp;
   for my $match (@{ $draw->{matches} }) {
      my @colors = qw/red blue green/;
      my $game = $fixture->create_related('games', { scheduled => $t });
      for my $ti (@$match) {
         my $team = $game->create_related('teams', {
            color => shift @colors,
         });

         my $players = $teams[$ti];
         for my $pi (0..$teamSize-1) {
            push @tp, {
               team_id => $team->id,
               player_id => $players->[$pi]->id,
            };
         }

         # Rotate the players on the team by the number of players it exceeds
         # the teamSize, such that each player on the team gets as equal
         # number of games as possible
         for ($teamSize..$#$players) {
            push @$players, shift @$players;
         }
      }

      $t->add(minutes => $gamelen);
   }
   $c->db('TeamPlayer')->populate(\@tp);

   $c->redirect_to('fixture-view', { fid => $fixture->id });
}

sub create {
   my $c = shift;

   my $t0 = $c->stash->{now}->clone;
   $t0->add(minutes => 5 - $t0->min % 5);

   $c->stash->{times} = [ map $t0->clone->add(minutes => $_ * 5), (0..12) ];
   $c->stash->{modes} = $c->db('Mode');
   $c->stash->{colors} = [ qw/red blue green orange cyan purple yellow pink/ ];
   $c->stash->{pens} = [ 1..5, 8, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100 ];
   $c->stash->{gamelens} = [ 1..5, 8, 10, 12, 15, 20, 25, 30 ];

   $c->add if $c->req->method eq 'POST';

   $c->render;
}

sub draw_gen {
   my $c = shift;

   my $draw = gen_draw(
      games => $c->parami('games') // 5,
      teams => $c->parami('teams') // 5,
      pen => {
         color => $c->parami('color') // 20,
         pair  => $c->parami('pair')  // 10,
         step  => $c->parami('step')  // 1,
      },
   );

   $draw->{id} = steady_time;
   $c->config->{drawCache}->set($draw->{id}, b64_encode encode_json $draw);

   $c->render(format => 'html', draw => $draw, template => 'fixture/draw');
}

sub draw_get {
   my $c = shift;

   my $draw = $Natty::Draw::PRESETS{$c->paramo('preset')}
      or return $c->reply->exception('Bad input');
   $c->config->{drawCache}->set($draw->{id}, b64_encode encode_json $draw);

   $c->render(format => 'html', draw => $draw, template => 'fixture/draw');
}

sub list {
   my $c = shift;

   $c->stash(
      fixtures => $c->db('Fixture')->ordered_rs,
   );

   $c->render;
}

sub view {
   my $c = shift;
   $c->render;
}

1;
