package Natty::Schema::Result::Player;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("players");

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
   "tag",
   { data_type => "text", is_nullable => 0 },
   "tag_normalised",
   { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many('team_players', 'Natty::Schema::Result::TeamPlayer', 'player_id');
__PACKAGE__->has_many('ratings', 'Natty::Schema::Result::Rating', 'player_id', { join_type => 'left' });
__PACKAGE__->has_many('rating_logs', 'Natty::Schema::Result::RatingLog', 'player_id', { join_type => 'left' });

__PACKAGE__->many_to_many('teams', 'team_players', [qw/player_id color/]);

1;
