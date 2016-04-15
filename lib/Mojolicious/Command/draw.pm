use utf8;
package Mojolicious::Command::draw;

use Data::Dump;
use Mojo::Base 'Mojolicious::Command';
use Natty::Draw qw/get_draw/;
use IO::Prompt;

sub run {
   my $self = shift;
   my %conf = (
      teams => shift // 5,
      games => shift // 9,
      tries => shift // 2_000,
   );
   my %stats;
   my $draw = get_draw(\%conf, \%stats);

   dd $draw, %stats;
}

1;
