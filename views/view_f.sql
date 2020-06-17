--VISTA_F that for the game with the highest volume of bets, show how the odd value of 
--each of the possible results has evolved over time. As in an hourly interval 
--(eg from 10 am to 11 am) the value of an odd can change more than once, 
--for each of the possible results, show the maximum value of the odd in each hour. 
--Order the result temporally.

--DataJogo equipa1 equipa2 dataHoraOdd oddVitoriaEq1 OddEmpate oddVitoriaEq2
---------- ------- ------- ----------- ------------- --------- -------------
create or replace view view_f as

select g.match_date, g.A_team_id, g.B_team_id, o.odd_date,
  round((select value from odds where game_id = g.game_id and odd_type_id = 1),2) as TeamAWin,
  round((select value from odds where game_id = g.game_id and odd_type_id = 2),2) as Draw,
  round((select value from odds where game_id = g.game_id and odd_type_id = 3),2) as TeamBWin
from games g, odds o
--odd_type_id = 1 prevents the same record from appearing 3 times
where g.game_id = o.game_id and o.odd_type_id = 1 and
      
--      take records from certain period of time (from 10 to 11)
      to_char(o.odd_date, 'HH24') > '10' and
      to_char(o.odd_date, 'HH24') < '11' and
--      
--      take only odds from game with the highest volume of bets
      g.game_id = (
            select g_game_id
            from (
                  select g.game_id as g_game_id, 
                         count(b.bet_id)        
                  from history_games g
                  join history_odds o on g.game_id = o.game_id
                  join bets b on o.odd_id = b.odd_id
                  group by g.game_id
                  order by count(b.bet_id) desc
                  )
--              take top 1
              where rownum = 1);

