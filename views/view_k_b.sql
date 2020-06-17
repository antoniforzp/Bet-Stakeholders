--list of top 10 underdogs(team which had big odd - not supposed to win) which actually won the game
--with the money won and name of that client (true_fan).

create or replace view view_k_a2019156557 as

select c.client_id,
       c.name,
       round(o.value,2) as odd_value,
       
--       take the team name depending on with team was the bet
       case when o.odd_type_id = 1 then
          (
            Select t.name
            from teams t
            where t.team_id = g.A_team_id
          )
          else
          (
            Select t.name
            from teams t
            where t.team_id = g.B_team_id
          ) 
          end as underdog
       
       
--    history_games -> odds -> bets -> payouts
--    I needed to find only games of odds of bets attached to payouts
--    because bet on certain odd is winning when there is and payout with the odd_id

from history_games g
join history_odds o on o.game_id = g.game_id
join bets b on o.odd_id = b.odd_id
join payouts p on b.bet_id = p.bet_id,
     clients c
     
where (o.odd_type_id = 1 or o.odd_type_id = 3) and
      p.client_id = c.client_id
      
order by o.value desc;

