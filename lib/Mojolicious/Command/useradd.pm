use utf8;
package Mojolicious::Command::useradd;

use Mojo::Base 'Mojolicious::Command';
use IO::Prompt;
use feature qw/fc/;

sub run {
   my $self = shift;
   my $users = $self->app->db('User');

   my $name = shift // prompt('Username: ');
   length $name >= 3
      or die "Username too short (min 3 chars)\n";
   !$users->search({ name_normalised => fc $name })->count
      or die "Username taken\n";

   my $password = prompt('Password: ');
   length $password >= 5
      or die "Password too short (min 5 chars)\n";

   my $user = $users->find(
      $users->create({
         name => $name,
         name_normalised => fc $name,
         password => $password,
      })->id
   );

   printf "Created user '%s' with password '%s'\n", $user->name, $user->password;
}

1;
