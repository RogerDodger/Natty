package Natty::Schema::Result::RatingX;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('ratingsx');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
   SELECT
      p.id AS player_id,
      p.tag AS player_tag,
      r.mu AS mu,
      r.sigma AS sigma,
      (r.mu - 2 * r.sigma * r.sigma) AS theta,
      (
         SELECT COUNT(*)
         FROM rating_logs rl
         LEFT JOIN games g
            ON g.id = rl.game_id
         LEFT JOIN fixtures f
            ON f.id = g.fixture_id
         WHERE rl.player_id = r.player_id
         AND f.mode_id = r.mode_id
      ) AS games
   FROM ratings r
   LEFT JOIN players p
      ON p.id = r.player_id
   WHERE r.mode_id = ?
   GROUP BY r.player_id
   ORDER BY mu DESC, sigma ASC, p.tag_normalised ASC
});

__PACKAGE__->add_columns(
   "player_id",
   { data_type => "integer" },
   "player_tag",
   { data_type => "text" },
   "mu",
   { data_type => "real" },
   "sigma",
   { data_type => "real" },
   "theta",
   { data_type => "real" },
   "games",
   { data_type => "integer" },
);

1;
