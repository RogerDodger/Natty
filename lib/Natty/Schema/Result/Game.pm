package Natty::Schema::Result::Game;
use Mojo::Base 'Natty::Schema::Result';

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
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to('mode', 'Natty::Schema::Result::Game', 'mode_id');
__PACKAGE__->has_many('teams', 'Natty::Schema::Result::Team', 'game_id');

1;
