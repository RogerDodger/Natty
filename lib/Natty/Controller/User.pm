package Natty::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

sub auth {
   my $c = shift;

   my $username = $c->param('username') // '';
   my $password = $c->param('password') // '';

   if ($c->helpers->auth($username, $password)) {
      $c->redirect_to($c->param('referrer') || '/');
   }
   else {
      $c->flash(error_msg => "Bad username or password");
      $c->flash(referrer => $c->param('referrer'));
      $c->redirect_to($c->url_for('login'));
   }
}

sub authd {
   my $c = shift;

   return 1 if $c->user;

   $c->res->code(403);
   $c->reply->exception("Not allowed!");
   undef;
}

sub login {
   my $c = shift;
   $c->stash(referrer => $c->flash('referrer') || $c->req->headers->referrer);
   $c->render;
}

sub logout {
   my $c = shift;
   delete $c->session->{__user_id};
   $c->redirect_to($c->req->headers->referrer || '/');
}

1;
