package Natty::Schema::ResultSet;

use Mojo::Base 'DBIx::Class::ResultSet';

sub find_maybe {
   my ($self, $id) = @_;
   $id =~ /^(\d+)$/ ? $self->find(int $1) : undef;
}

sub order_by {
   my $self = shift;
   return $self->search({}, { -order_by => shift });
}

sub prefetch {
   shift->search({}, { prefetch => shift });
}

1;
