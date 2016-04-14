package Natty;
use Mojo::Base 'Mojolicious';

use Class::Null;
use Natty::DateTime;
use Natty::Schema;
use feature qw/fc/;

sub startup {
   my $self = shift;

   $self->log(Mojo::Log->new);

   $self->plugin('PlainRoutes');
   $self->plugin(EPRenderer => {
      name     => 'epm',
      template => {
         tag_start => '{{',
         tag_end   => '}}'
      }
   });

   $self->config({
      dsn => 'dbi:SQLite:site/natty.db',
      now => Natty::DateTime->now,
   });

   $self->helper(db => sub {
      my ($c, $table) = @_;
      state $schema = Natty::Schema->connect($c->config->{dsn},'','', {
         sqlite_unicode => 1,
      });
      defined $table ? $schema->resultset($table) : $schema;
   });

   $self->helper(auth => sub {
      my ($c, $username, $password) = @_;

      my $user = $c->db('User')->search({ name_normalised => fc $username })->first;

      if ($user && $user->check_password($password)) {
         $c->session->{__user_id} = $user->id;
         return $user;
      }

      return undef;
   });

   $self->helper(user => sub {
      my $c = shift;

      $c->stash->{__user}
         ? $c->stash->{__user}
         : $c->session->{__user_id}
            ? ($c->stash->{__user} //=
               $c->db('User')->find($c->session->{__user_id}))
            : Class::Null->new;
   });
}

1;
