package Natty::Schema::Result::Fixture;
use Mojo::Base 'Natty::Schema::Result';

use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw/b64_encode b64_decode/;

__PACKAGE__->table("fixtures");

__PACKAGE__->load_components(qw/FilterColumn/);

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
   "mode_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "draw",
   { data_type => "text", is_nullable => 0 },
   "start",
   { data_type => "timestamp", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->filter_column('draw', {
   filter_from_storage => sub {
      decode_json b64_decode $_[1];
   },
});

__PACKAGE__->has_many('games', 'Natty::Schema::Result::Game', 'fixture_id');
__PACKAGE__->belongs_to('mode', 'Natty::Schema::Result::Mode', 'mode_id');

1;
