--VISTA_I showing the top 10 players / punters who have been paid the highest total 
--prize amounts. Consider the total amount of prizes paid since the beginning of 
--the current year and whose total amount received in prizes is greater than 100% 
--of the total amount spent on these bets. Consider only those players who have bet 
--on at least 10% of the games that occurred during that period. Sort descendingly 
--by the total amount paid in premiums.

--NomeJogador AnoMes(?) MontanteTotalApostado MontanteTotalPremios
------------- ------ --------------------- ---------------------

create or replace view view_i as

select *
from (
          select c.name,
               round(sum(b.money_placed),2) as money_placed, 
               round(sum(p.money),2) as money_won
        
        --join clients with payouts
        --  client -> bets -> odds -> payouts
        from clients c
        join bets b on c.client_id = b.client_id
        join history_odds o on b.odd_id = o.odd_id
        join payouts p on b.bet_id = p.bet_id
        
        --join odds with games
        join history_games g on o.game_id = g.game_id
        
        --take only matches from last year
        where g.match_date > add_months(sysdate, -1 * 12)
        group by c.client_id, c.name
        
        --players who have bet on at least 10% of the games that occurred during that period
        having count(g.game_id) < (
                        select count(game_id) * 0.1 as tenPercent
                        from history_games
                        --take only matches from last year
                        where match_date > add_months(sysdate, -1 * 12)
                      ) and
                    
        --            total amount received in prizes is greater than 100% of the total amount spent on these bets
                    sum(p.money) > sum(b.money_placed) 
                    
        --Sort descendingly by the total amount paid in premiums.
        order by money_won desc
)
--showing the top 10 players
where rownum <= 10;