package Natty::Schema::Result::User;
use Mojo::Base 'Natty::Schema::Result';

use Bytes::Random::Secure qw/random_bytes/;
use Crypt::Eksblowfish::Bcrypt qw/bcrypt en_base64/;

my $rng = Bytes::Random::Secure->new(NonBlocking => 1);

__PACKAGE__->load_components(qw/FilterColumn/);

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
	"id",
	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"name",
	{ data_type => "text", is_nullable => 0 },
	"name_normalised",
	{ data_type => "text", is_nullable => 0 },
	"password",
	{ data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->filter_column('password', {
	filter_to_storage => sub {
		my ($obj, $plain) = @_;

		my $cost = '10';
		my $salt = en_base64 $rng->bytes(16, '');
		my $settings = join '$', '$2', $cost, $salt;

		bcrypt($plain, $settings);
	}
});

sub check_password {
	my ($self, $plain) = @_;

	bcrypt($plain, $self->password) eq $self->password;
}

1;
