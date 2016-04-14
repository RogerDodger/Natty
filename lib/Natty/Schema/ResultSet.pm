package Natty::Schema::ResultSet;

use Mojo::Base 'DBIx::Class::ResultSet';

sub datetime_parser {
   shift->result_source->schema->storage->datetime_parser;
}

sub format_datetime {
   shift->datetime_parser->format_datetime(shift);
}

sub parse_datetime {
   shift->datetime_parser->parse_datetime(shift);
}

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
