package Natty::Controller::Player;
use Mojo::Base 'Mojolicious::Controller';
use Natty::Rating;
use feature qw/fc/;

sub add {
   my $c = shift;
   my $tags = $c->param('tags') // '';
   my $players = $c->db('Player');

   my @exists;
   for my $tag (split /\s+/, $tags) {
      next unless $tag =~ /[\w\d]/;

      if ($players->search({ tag_normalised => fc $tag })->count) {
         push @exists, $tag;
         next;
      }

      my $player = $players->create({
         tag => $tag,
         tag_normalised => fc $tag,
      });

      for my $mode ($c->db('Mode')->all) {
         $player->create_related('ratings', {
            mode_id => $mode->id,
            mu => Natty::Rating::MU_INIT,
            sigma => Natty::Rating::SIGMA_INIT,
         });
      }

   }

   if (@exists) {
      $c->flash(error_msg => "Player(s) already exist: " . join ", ", @exists);
   }

   $c->redirect_to('players');
}

sub list {
   my $c = shift;


   my $mode = $c->db('Mode')->find_maybe($c->param('mode') || 1);
   die "???" unless $mode;

   $c->stash(
      modes => $c->db('Mode')->search_rs({}, {
         order_by => { -asc => 'id' },
      }),
      mode => $mode,
      ratings => $mode->ratings->with_theta->search_rs({}, {
         prefetch => 'player',
         order_by => [
            { -desc => 'theta' },
            { -asc  => 'player.tag_normalised' },
         ]
      }),
   );

   $c->render;
}

1;
