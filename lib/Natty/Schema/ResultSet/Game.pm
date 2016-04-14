package Natty::Schema::ResultSet::Game;
use Mojo::Base 'Natty::Schema::ResultSet';

sub active {
   shift->search_rs({ finished => undef }, {
      order_by => { -asc => 'scheduled' },
   })
}

sub finalise {
   my ($self, $game) = @_;

   $self->search({
      finalised => 0,
      finished => { '!=' => undef },
      id => { '!=' => $game->id },
   })->update({
      finalised => 1
   });
}

sub finished {
   shift->search_rs({ finished => { '!=' => undef }}, {
      order_by => { -desc => 'scheduled' },
   });
}

1;
