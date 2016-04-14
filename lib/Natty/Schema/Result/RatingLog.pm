package Natty::Schema::Result::RatingLog;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("rating_logs");

__PACKAGE__->add_columns(
   "player_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "game_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "theta_orig",
   { data_type => "real", is_nullable => 0 },
   "theta_diff",
   { data_type => "real", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("player_id", "game_id");

__PACKAGE__->belongs_to('player', 'Natty::Schema::Result::Player', 'player_id');
__PACKAGE__->belongs_to('game', 'Natty::Schema::Result::Game', 'game_id');

1;
