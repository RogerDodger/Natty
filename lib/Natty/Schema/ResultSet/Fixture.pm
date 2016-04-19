package Natty::Schema::ResultSet::Fixture;
use Mojo::Base 'Natty::Schema::ResultSet';

sub ordered {
   shift->search({}, { order_by => { -desc => 'start' } });
}

sub ordered_rs { scalar shift->ordered(@_) }

1;
