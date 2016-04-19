package Natty::Schema::Result::Team;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table("teams");

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
   "game_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "preset_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
   "color",
   { data_type => "text", is_nullable => 0 },
   "score",
   { data_type => "integer", is_nullable => 1 },
   "rank",
   { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to('game', 'Natty::Schema::Result::Game', 'game_id');
__PACKAGE__->belongs_to('preset', 'Natty::Schema::Result::Preset', 'preset_id');
__PACKAGE__->has_many('team_players', 'Natty::Schema::Result::TeamPlayer', "team_id");

__PACKAGE__->many_to_many('players', 'team_players', 'player_id');

sub playersx {
   my $self = shift;
   $self->result_source->schema->resultset('TeamPlayerX')->search({}, { bind => [ $self->id ] });
}

sub mu {
   my $self = shift;

   $self->{__mu} //= $self->players->search({}, { join => 'player' })->get_column('player.rating_mu')->sum;
}

sub sigma {
   my $self = shift;

   $self->{__sigma} //= $self->players->search({}, { join => 'player' })->get_column('player.rating_sigma')->sum;
}

1;
