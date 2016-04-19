package Natty::Controller::Team;
use Mojo::Base 'Mojolicious::Controller';
use List::Util qw/shuffle sum min max/;

sub generate {
   my $c = shift;
   my $mode = $c->db('Mode')->find_maybe($c->param('mode') // 1)
      or return $c->reply->exception('Invalid mode');

   my $cache = $c->config->{onlineCache};
   my @players = grep $cache->get($_->player_id),
                    $c->db('RatingX')->search({}, { bind => [ $mode->id ] })->all;

   my $size = $c->paramo('teams') =~ m{(\d+)} ? int $1 : int (@players / 5);

   my %best;
   for (0..1_000) {
      my @teams = map { [] } 0..$size-1;

      @players = shuffle @players;
      push @teams[$_ % $size], $players[$_] for 0..$#players;

      my @mu  = map { @$_ && sum(map $_->mu, @$_) / @$_ } @teams;
      my $pen = max(@mu) - min(@mu);

      if (!%best || $pen < $best{pen}) {
         %best = (pen => $pen, teams => \@teams);
      }
   }

   for (@{ $best{teams} }) {
      @$_ = map $_->player_tag,
              reverse sort { $a->mu <=> $b->mu }
                 @$_;
   }

   $c->render(json => \%best);
}

sub sub {
  my $c = shift;

  my $tp = $c->db('TeamPlayer')->find($c->parami('oldp_id'), $c->parami('team_id'));
  my $sub = $c->db('RatingX')->search(
    { player_id => $c->parami('newp_id') },
    { bind => [ 1 ] },
  )->first;

  if ($tp && $sub) {
    my $game = $tp->team->game;

    return $c->reply->exception if $game->finished || $game->teams->search(
      { player_id => $sub->player_id },
      {
        join => { 'team_players' },
      },
    )->count;

    $tp->update({ player_id => $sub->player_id });
    return $c->respond_to(
      ajax => { json => {
        id => $sub->player_id,
        tag => $sub->player_tag,
        mu => (sprintf "%.2f", $sub->mu),
      }},
    )
  }

  $c->reply->exception;
}

1;
