--list of most aggresive teams - counted numer of fauls

create or replace view view_k_a2019156734 as

select t.name, 
      event_count.total
from (
--        get team_id and counted total fouls
        select e.team_id as e_team_id, 
        count(et.event_type_id) as total
        
        from history_games g
        join events e on g.game_id = e.game_id
        join event_type et on e.event_type_id = et.event_type_id

--        foul is an event of type 11
        where et.event_type_id = 11
        group by e.team_id       
        
      ) event_count
--        join subquery with teams table to obtain the name of the team
      join teams t on event_count.e_team_id = t.team_id
      
order by event_count.total desc;