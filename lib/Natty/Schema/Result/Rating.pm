package Natty::Schema::Result::Rating;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("ratings");

__PACKAGE__->add_columns(
   "player_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "mode_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "mu",
   { data_type => "real", is_nullable => 0 },
   "sigma",
   { data_type => "real", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("player_id", "mode_id");

__PACKAGE__->belongs_to('player', 'Natty::Schema::Result::Player', 'player_id');
__PACKAGE__->belongs_to('mode', 'Natty::Schema::Result::Mode', 'mode_id');

sub theta {
   shift->get_column('theta');
}

1;
