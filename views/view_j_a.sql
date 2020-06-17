--Players' percentage contribution in Company's pure income. In other words,
--in which precentage company earn from clients looses
--contribution = total_placed - total_payout
--company_pure_income = contribution of all cients
--(How much money in percentage bettor left in company loosing)

create or replace view view_j_a2019156557 as

select c.client_id,
      c.name,
      c.surname,
      round(
--      calculate client contribution
      (client_sum_bet.total - client_sum_payout.total) / 
--      divide by
      (
--        calculate all company pure income
--        total money placed by clients - total money paid out
        (select sum(b.money_placed) from bets b) -
        (select round(sum(p.money),2) from payouts p)
      ) * 100,2) as precetnage_contribution
      
from clients c,
    (
--    get client_id with all money placed by this client
      select b.client_id as b_client_id, 
      sum(b.money_placed) as total
      from bets b
      group by b.client_id
    ) client_sum_bet,
    (
--    get client_id with all monet won(paid by company) by this client
      select p.client_id as p_client_id, 
      round(sum(p.money),2) as total
      from payouts p
      group by p.client_id
    ) client_sum_payout 
    
--    connect total sum and payouts from clients
where c.client_id = client_sum_bet.b_client_id and
      c.client_id = client_sum_payout.p_client_id
order by precetnage_contribution desc;



