--VISTA_A that, for each of the games of the current season of the national football 
--championship of Liga Nos, shows the date of the game, the visited and visiting team, 
--the number of goals of each team, and the result information in the format (1, x, 2), 
--when, respectively, there is a victory for the visited team (1), a tie (x), or a victory 
--for the visiting team (2). Sort the results by the date of the game.

--Jornada DataJogo equipaVisitada equipaVisitante resultado
--------- -------- --------------- --------------- ---------

create or replace view view_a AS
select hg.phase_id   as Round,
       hg.match_date as MatchDate,
       hg.A_team_id  as Hosts,
       hg.B_team_id  as Visitors,

--        case inserting 1,2,x depending on the match result 
       case
           when hg.A_goals > hg.B_goals then '1'
           when hg.A_goals < hg.B_goals then '2'
           when hg.A_goals = hg.B_goals then 'x'
           else ''
           end       as match_result

from history_games hg
         join phases p
              on hg.phase_id = p.phase_id
where p.competition_id = 'LN'
order by match_date;
