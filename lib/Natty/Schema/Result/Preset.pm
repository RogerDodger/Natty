package Natty::Schema::Result::Preset;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("presets");

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
   "name",
   { data_type => "text", is_nullable => 0 },
   "created",
   { data_type => "timestamp", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many('players', 'Natty::Schema::Result::Player', 'preset_id');

1;
