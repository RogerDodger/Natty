package Natty::Schema::ResultSet::Rating;
use Mojo::Base 'Natty::Schema::ResultSet';

sub with_theta {
   shift->search({}, {
      '+select' => [{ q{} => \'me.mu - 2 * (me.sigma * me.sigma)', -as => 'theta' }],
      '+as' => 'theta',
   });
}

1;
