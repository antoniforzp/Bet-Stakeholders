--VISTA_E that considering all the bets of the games registered in the last 
--2 years show which players have abnormal bets, that is, whose total value 
--bet by the player is greater than 10% of the total bet in that game by all the bettors. 
--Sort the result in descending order by percentage.

--DataJogo equipaVisitada equipaVisitante NomeJogador TotalApostado Percent
---------- -------------- --------------- ----------- ------------- -------

create or replace view view_e as

select g.match_date,
       g.A_team_id,
       g.B_team_id, 
       c.name, 
       b.money_placed, 
       round(b.money_placed / game_total_sum.total_money * 100,2) as percentage
       
--       connect games with odds and bets with bettors
--       games -> odds -> bets -> clinets
from history_games g
left outer join history_odds o on g.game_id = o.game_id
left outer join bets b on o.odd_id = b.odd_id
join clients c on b.client_id = c.client_id,
(
--      game_id with the total monet placed on that game
      select ga.game_id as ga_game_id, 
--      if there is no money placed (sum = null) place 0
             coalesce(sum(b.money_placed),0) as total_money
             
      from history_games ga
      left outer join history_odds o on ga.game_id = o.game_id
      left outer join bets b on o.odd_id = b.odd_id
      left outer join clients c on b.client_id = c.client_id
      group by ga.game_id
      
      ) game_total_sum
    
--      take only matches from past two years
where g.match_date > add_months(sysdate, -2 * 12) and

--      bet by the player is greater than 10% of the total bet in that game by all the bettors.
      b.money_placed > game_total_sum.total_money * 0.1 and
      
--      connect game_id from total sum with current game listed
      game_total_sum.ga_game_id = g.game_id
order by percentage asc;

