package Natty::Schema::Result::TeamPlayer;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("team_players");

__PACKAGE__->add_columns(
   "player_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "team_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("player_id", "team_id");

__PACKAGE__->belongs_to('player', 'Natty::Schema::Result::Player', 'player_id');
__PACKAGE__->belongs_to('team', 'Natty::Schema::Result::Team', 'team_id');

1;
