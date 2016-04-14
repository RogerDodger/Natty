package Natty::Schema::Result::TeamPlayerX;
use Mojo::Base 'Natty::Schema::Result';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('team_playersx');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
   SELECT
      p.id AS id,
      p.tag AS tag,
      IFNULL(rl.theta_orig,
             r.mu - (r.sigma * r.sigma) * 2)
                  AS theta_orig,
      rl.theta_diff AS theta_diff

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

   ORDER BY theta_orig DESC
});

__PACKAGE__->add_columns(
   "id",
   { data_type => "integer" },
   "tag",
   { data_type => "text" },
   "theta_orig",
   { data_type => "real" },
   "theta_diff",
   { data_type => "real" },
);

1;
