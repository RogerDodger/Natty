package Natty::DateTime;
use DateTime;
use DateTime::Format::RFC3339;

sub now {
   if (my $t = $ENV{NATTY_DATETIME}) {
      return DateTime::Format::RFC3339->parse_datetime($t);
   }

   DateTime->now;
}

1;
