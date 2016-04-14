package Natty::Schema::Result::Mode;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("modes");

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "name",
   { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many('games', 'Natty::Schema::Result::Game', 'mode_id');
__PACKAGE__->has_many('ratings', 'Natty::Schema::Result::Rating', 'mode_id');

1;
