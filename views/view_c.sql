--VISTA_C that considering all the games played so far in the current season of 
--the national football championship of Liga Nos, show for each team, their 
--classification, the number of games played, the number of wins, the number of 
--draws, the number of losses and the number of points obtained. 
--Consider that 3 points are awarded for each victory and 1 point for each tie. 
--The ranking criteria are: the number of points, the lowest number of games played,
--and the highest number of victories.

--Classif nomeEquipa nJogos NVitorias NEmpates NDerrotas NPontos
--------- ----------- ------ --------- --------- --------- -------

create or replace view view_c as

select row_number() over 
--        number rows orderer by points scored
       (order by (s.won*3) + s.draw desc, s.played, s.won desc) as place, 
       t.name, 
       s.played, 
       s.won, 
       s.draw, 
       s.lost, 
       (s.won*3) + s.draw as points 

from teams t, team_statistics s
where t.team_id = s.team_id and s.competition_id = (
        select competition_id
        from competitions
        where name = 'Liga NOS' and season = '2019/20');