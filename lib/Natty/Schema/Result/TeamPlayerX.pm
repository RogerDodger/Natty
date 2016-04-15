package Natty::Schema::Result::TeamPlayerX;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('team_playersx');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
   SELECT
      p.id AS id,
      p.tag AS tag,
      IFNULL(rl.mu, r.mu) AS mu,
      IFNULL(rl.sigma, r.sigma) AS sigma,
      IFNULL(rl.mu - 2 * (rl.sigma * rl.sigma),
             r.mu - 2 * (r.sigma * r.sigma)) AS theta,
      rl.theta_delta AS theta_delta,
      rl.mu_delta AS mu_delta
   FROM teams t
   LEFT JOIN games g
      ON g.id = t.game_id
   LEFT JOIN team_players tp
      ON tp.team_id = t.id
   LEFT JOIN players p
      ON p.id = tp.player_id
   LEFT JOIN ratings r
      ON r.player_id = p.id
      AND r.mode_id = g.mode_id
   LEFT JOIN rating_logs rl
      ON rl.player_id = p.id
      AND rl.game_id = g.id

   WHERE t.id = ?

   ORDER BY mu DESC
});

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer" },
   "tag",
   { data_type => "text" },
   "mu",
   { data_type => "real" },
   "sigma",
   { data_type => "real" },
   "theta",
   { data_type => "real" },
   "theta_delta",
   { data_type => "real" },
   "mu_delta",
   { data_type => "real" },
);

1;
