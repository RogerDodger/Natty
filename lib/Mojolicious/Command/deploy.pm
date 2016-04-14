use utf8;
package Mojolicious::Command::deploy;

use Mojo::Base 'Mojolicious::Command';
use IO::Prompt;

sub run {
   my $self = shift;

   printf "Deploying %s...\n", $self->app->moniker;
   my $fn = $self->app->config->{dsn} =~ s/.+://gr;
   my $writedb = 1;
   if (-f $fn) {
      $writedb = prompt "Database file $fn already exists. Overwrite it? [y/n] ", '-y';
      unlink $fn if $writedb;
   }

   if ($writedb) {
      my $s = Natty::Schema->connect($self->app->config->{dsn});

      $s->deploy;
      $s->resultset('Mode')->populate([
         { name => "Nats" },
         { name => "LotR" },
      ])
   }
}

1;
