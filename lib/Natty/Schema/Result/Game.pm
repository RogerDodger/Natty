package Natty::Schema::Result::Game;
use Mojo::Base 'Natty::Schema::Result';
use List::Util qw/max/;
use Natty::Rating;

__PACKAGE__->table("games");

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
   "mode_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "scheduled",
   { data_type => "timestamp", is_nullable => 0 },
   "finished",
   { data_type => "timestamp", is_nullable => 1 },
   "finalised",
   { data_type => "boolean", is_nullable => 0, default_value => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to('mode', 'Natty::Schema::Result::Game', 'mode_id');
__PACKAGE__->has_many('rating_logs', 'Natty::Schema::Result::RatingLog', 'game_id');
__PACKAGE__->has_many('teams', 'Natty::Schema::Result::Team', 'game_id');

# Algorithm 1 from https://www.csie.ntu.edu.tw/~cjlin/papers/online_ranking/
sub update_ratings {
   my $self = shift;
   my $schema = $self->result_source->schema;

   # Step 1. Define parameters
   my $beta = Natty::Rating::BETA;
   my $K = Natty::Rating::K;

   # Step 2. Calculate team mu/sigma^2
   my @teams = $self->teams->all;

   for my $team (@teams) {
      $team->{mu} = $team->{sigsq} = 0;
      $team->{players} = [ $team->playersx->all ];

      for my $player (@{ $team->{players} }) {
         $team->{mu} += $player->mu;
         $team->{sigsq} += $player->sigma ** 2;
      }
   }

   # Step 3. For each team
   for my $i (0..$#teams) {
      my $Omega = 0;
      my $Delta = 0;

      # Step 3.1. Team skill update
      for my $q (0..$#teams) {
         next if $i == $q;

         my $ciq = sqrt($teams[$i]->{sigsq} + $teams[$q]->{sigsq} + 2 * $beta**2);
         my $piq = 1 / (1 + exp(($teams[$q]->{mu} - $teams[$i]->{mu}) / $ciq));
         my $sigsq_to_ciq = $teams[$i]->{sigsq} / $ciq;
         my $s = 0;
            $s = 0.5 if $teams[$i]->score == $teams[$q]->score;
            $s = 1   if $teams[$i]->score > $teams[$q]->score;

         # my $gamma = (1 / @teams);
         my $gamma = sqrt($teams[$i]->{sigsq}) / $ciq;
         $Omega += $sigsq_to_ciq * ($s - $piq);
         $Delta += $gamma * $sigsq_to_ciq / $ciq * $piq * (1 - $piq);
      }

      # Step 3.2. Individual skill update
      for my $player (@{ $teams[$i]->{players} }) {
         my $sigsq = $player->sigma ** 2;
         my $mu    = $player->mu
                   + $sigsq / $teams[$i]->{sigsq} * $Omega;
         my $sigma = $player->sigma
                   * sqrt(max(1 - $sigsq / $teams[$i]->{sigsq} * $Delta, $K));
         my $theta = $mu - 2 * $sigma**2;

         $schema->resultset('Rating')->find($player->id, $self->mode_id)->update({
            mu => $mu,
            sigma => $sigma,
         });

         my $log = $schema->resultset('RatingLog')->find($player->id, $self->id);
         if (!$log) {
            $log = $schema->resultset('RatingLog')->new_result({
               player_id => $player->id,
               game_id => $self->id,
            });
         }
         $log->mu($player->mu);
         $log->sigma($player->sigma);
         $log->theta_delta($theta - $player->theta);
         $log->mu_delta($mu - $player->mu);
         $log->in_storage ? $log->update : $log->insert;
      }
   }
}

1;
