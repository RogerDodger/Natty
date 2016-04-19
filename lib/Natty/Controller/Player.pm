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

   $c->redirect_to('player-ratings');
}

sub ratings {
   my $c = shift;

   my $mode = $c->db('Mode')->find_maybe($c->param('mode') || 1)
      or return $c->reply->exception("Unknown mode");

   $c->stash(
      modes => $c->db('Mode')->search_rs({}, {
         order_by => { -asc => 'id' },
      }),
      mode => $mode,
      ratings => $c->db('RatingX')->search_rs({}, { bind => [ $mode->id ] }),
   );

   $c->render;
}

sub offline_all {
   my $c = shift;
   $c->config->{onlineCache}->clear;
   $c->respond_to({
      ajax => { text => 'okay' },
      html => sub { $c->redirect_to($c->req->headers->referrer || '/'); },
   });
}

sub online {
   my $c = shift;
   my $cache = $c->config->{onlineCache};
   my $pid = $c->param('pid');
   my $ret = 0 + !$cache->get($pid);
   $cache->get($pid) ? $cache->remove($pid) : $cache->set($pid, 1);

   $c->respond_to(
      ajax => { text => $ret },
      html => sub { $c->redirect_to($c->req->headers->referrer || '/') },
   );
}

sub online_all {
   my $c = shift;
   my $cache = $c->config->{onlineCache};
   $cache->set($_->id, 1) for $c->db('Player')->all;

   $c->respond_to(
      ajax => { text => 'okay' },
      html => sub { $c->redirect_to($c->req->headers->referrer || '/') },
   );
}

1;
