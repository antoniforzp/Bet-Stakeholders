--List of clients with their win ratio of all

create or replace view view_j_a2019156734 as

select c.client_id,
       c.name,
       c.surname,
       round(p.total_wins / b.total_bets * 100,2) win_ratio, 
       b.total_bets
       
from clients c,
    (
--    get client_id with client's counted all bets
      select b.client_id as b_client_id, count(b.bet_id) as total_bets
      from bets b
      group by b.client_id
    ) b,
    (
--    get client_id with client's counted all payouts 
--    (if there is payout with bet_id, this bet is won)
      select p.client_id as p_client_id, count(p.payout_id) as total_wins
      from payouts p
      group by p.client_id
    ) p
--    connect all subqueries
where c.client_id = b.b_client_id and c.client_id = p.p_client_id
--order results by the winratio
order by round(p.total_wins / b.total_bets * 100,2) desc;