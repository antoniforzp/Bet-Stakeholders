--VISTA_B that, for each of the games of the last matchday of the current season of 
--the national football championship of Liga Nos, show the date of the game, 
--the visited and visiting team, the total amount bet and the total amount of 
--prizes paid to the bettors who won the respective bets. Sort the results by the total stake.

--DataJogo equipaVisitada equipaVisitante TotalApostado totalPremios
----------- -------------- --------------- -------------- ------------

create or replace view VIEW_B as
select match_date,
       A_team_id,
       B_team_id,
       odds_sums.sum_bets,
       payouts_sums.sum_payouts

from history_games g,
     (
--    get games_id with the total money bet on that game
         select GAME_ID                as total_game_id,
                round(PLACED_TOTAL, 2) as sum_bets
         from CALC_TOTAL
     ) odds_sums,

     (
--    get games_id with the total prizes paid for that game
         select o.game_id              as o_game_id,
                round(sum(p.money), 2) as sum_payouts
         from history_odds o
                  join bets b on o.odd_id = b.odd_id
                  join payouts p on b.bet_id = p.bet_id
         group by o.game_id
     ) payouts_sums

--      connect odds and prizes by the same game_id
where g.game_id = odds_sums.total_game_id
  and g.game_id = payouts_sums.o_game_id

--      there are some games the money is not bet on
  and odds_sums.sum_bets is not null
  and payouts_sums.sum_payouts is not null

--      select only those matches with the latest match_date but only 
--      with that which have a payouts
  and phase_id = (select max(phase_id)
                  from history_games g
                           join history_odds o on o.game_id = g.game_id
                           join bets b on b.odd_id = o.odd_id
                           join payouts p on p.bet_id = b.bet_id)
order by payouts_sums.sum_payouts desc;