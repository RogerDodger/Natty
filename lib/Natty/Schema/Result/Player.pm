package Natty::Schema::Result::Player;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("players");

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
   "preset_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
   "tag",
   { data_type => "text", is_nullable => 0 },
   "tag_normalised",
   { data_type => "text", is_nullable => 0 },
   "active",
   { data_type => "boolean", is_nullable => 0, default_value => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many('team_players', 'Natty::Schema::Result::TeamPlayer', 'player_id');
__PACKAGE__->has_many('ratings', 'Natty::Schema::Result::Rating', 'player_id');
__PACKAGE__->has_many('rating_logs', 'Natty::Schema::Result::RatingLog', 'player_id');
__PACKAGE__->belongs_to('preset', 'Natty::Schema::Result::Preset', 'preset_id');

__PACKAGE__->many_to_many('teams', 'team_players', [qw/player_id color/]);

1;
