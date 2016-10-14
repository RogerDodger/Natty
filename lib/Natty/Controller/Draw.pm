package Natty::Controller::Draw;
use Natty::Base 'Mojolicious::Controller';
use Natty::Draw;

sub list ($c) {
   $c->render(draws => \@Natty::Draw::PRESETS);
}

sub parse ($c) {
   select undef, undef, undef, 0.5;

   $c->stash->{draw} = Natty::Draw->parse($c->paramo('draw'));
   $c->app->log->info($c->dumper($c->stash->{draw}->timeline));

   $c->render(format => 'html', template => 'draw/breakdown');
}

sub teams ($c) {
   $c->render(format => 'html', tempalte => 'draw/teams');
}

1;
