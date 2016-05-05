use utf8;
package Mojolicious::Command::draw;

use Data::Dump;
use Mojo::Base 'Mojolicious::Command';
use Natty::Draw qw/gen_draw/;
use IO::Prompt;

sub run {
   my $self = shift;

   # my %conf;
   # my @k = qw/teams games tries/;
   # while (my $val = shift) {
   #    $conf{shift @k} = $val;
   # }
   # my $draw = gen_draw(\%conf);

   dd $Natty::Draw::PRESETS[shift // 0];
}

1;
