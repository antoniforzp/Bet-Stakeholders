--VISTA_D that considering all the bets registered in the last 2 years show which 
--are the 10 games with the highest volume ($$) of bets. Also show the number of players. 
--Sort descending by the total stake.

--DataJogo equipaVisitada equipaVisitante TotalApostado NumApostadores
----------- -------------- --------------- -------------- -----------------

create or replace view view_d as

select * from(
  select g.match_date, 
         g.A_team_id as visited, 
         B_team_id as visiting, 
         sum(b.money_placed) as bets, 
         count(o.game_id) as bettors
         
  from bets b, history_odds o, games g
  
--  connect subqueries
  where o.odd_id = b.odd_id and o.game_id = g.game_id and
        
--  form recent two years
        g.match_date > add_months(sysdate, -2 * 12)
  group by g.match_date, g.A_team_id, B_team_id
  order by bets desc)
  
--  take top 10. Rownum is in outer query in order to take into account 'order by' clause.
where rownum <= 10;