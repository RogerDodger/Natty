#/usr/bin/env perl

use 5.014;
use Getopt::Long;

GetOptions(\my %opt, 'devel|development');

my @production = qw/
   Mojolicious
   Mojolicious::Plugin::PlainRoutes
   DBIx::Class
   DBIx::Class::FilterColumn
   SQL::Translator
   IO::Socket::SSL
   Bytes::Random::Secure
   Crypt::Eksblowfish::Bcrypt
   Class::Null
   IO::Prompt
   DateTime
   DateTime::Format::RFC3339
   DateTime::Format::Human::Duration
   Cache::FastMmap
   CHI
   CHI::Driver::FastMmap
/;

my @development = qw/
   Text::Lorem::More
/;

if (eval { require App::cpanminus; 1; }) {
   *install = sub { system 'cpanm', @_ };
}
else {
   require CPAN;
   CPAN->import;
}

say "Installing production dependencies...";
install(@production);

if ($opt{devel}) {
   say "Installing development dependencies...";
   install(@development);
}
