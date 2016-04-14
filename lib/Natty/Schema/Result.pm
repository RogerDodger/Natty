package Natty::Schema::Result;

use Mojo::Base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

1;
