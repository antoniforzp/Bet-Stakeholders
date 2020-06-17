--VISTA_G that shows the next 10 games scheduled, and not yet played, and for one 
--of them shows the current value of the odd of each of the possible results. 
--Sort the result by the date of the game (closest to first).

--DataJogo equipaVisitada equipaVisitante oddVitoriaEq1 OddEmpate oddVitoriaEq2
---------- --------------- --------------- ------------- --------- -------------

create or replace view view_g as

select * 
from(
  select g.match_date, 
         g.A_team_id, 
         g.B_team_id,
         (
--         get odd for the win
            select round(value,2)
            from odds
            where game_id = g.game_id and odd_type_id = 1
          ) as odd_1, 
          (
--          get odd for the draw
            select round(value,2)
            from odds
            where game_id = g.game_id and odd_type_id = 2
          ) as odd_x, 
          (
--          get odd for the lost
            select round(value,2)
            from odds
            where game_id = g.game_id and odd_type_id = 3
          ) as odd_2
          
  from games g
--  get following games

--IT WILL NOT PRODUCE OUTPUT BECAUSE THERE IS NO GAME PLANNED AFTER TODAY'S DATE
  where g.match_date > sysdate
  order by g.match_date
  )
--  get ten matches
where rownum <= 10;