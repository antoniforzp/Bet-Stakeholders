--VISTA_H that for each team, show which game was assigned a higher win result value. 
--Consider only the games played in the previous month. Sort descending by the highest odd.

--DataJogo equipaVisitada equipaVisitante oddVitoriaEq
---------- --------------- --------------- ------------

create or replace view view_h as

select g1.match_date,
       g1.A_team_id,
       g1.B_team_id,
       max_odds_games.max_odd
       
from history_games g1,
     (
--          get game_id and max odd value for that game
--          subquery is used to avoid disconnection from other join tables
          select g.game_id as g_game_id,
                 round(max(o.value),2) as max_odd
          from history_games g
          join history_odds o on g.game_id = o.game_id
          
--          take only odd beting winning teamA or teamB
          where o.odd_type_id = 1 or o.odd_type_id = 3
          group by g.game_id
          order by round(max(o.value),2) desc
      ) max_odds_games
      
where g1.game_id = max_odds_games.g_game_id and
--          take only matches from previous month
--          greater then first day of previous month:
      g1.match_date > last_day(add_months(sysdate,-2))+1 and
--          smaller then last day of previous month:
      g1.match_date < last_day(add_months(sysdate,-1));