--BET TABLE

create trigger K_UPDATE_BET_BALANCE
    after insert
    on BETS
    for each row
declare
begin
    update CLIENTS set BALANCE = BALANCE - :new.money_placed where CLIENT_ID = :new.client_id;
end;
/

create trigger L_FILL_BET
    before insert
    on BETS
    for each row
declare
    v_bet_date    timestamp;
    v_odd_value   odds.value%type;
    v_odd_type    odds.odd_type_id% type;
    v_probability number;
    v_A_team_id   teams.team_id%type;
    v_B_team_id   teams.team_id%type;
begin
    --     assign sysdate to new inserted row
    v_bet_date := sysdate;
    :new.BET_DATE := v_bet_date;

-- get value and type of odd by odd_id
    select VALUE, ODD_TYPE_ID
    into v_odd_value, v_odd_type
    from ODDS
    where ODD_ID = :new.ODD_ID;

--     get teams ids of the game with particular odd
    select A_TEAM_ID, B_TEAM_ID
    into v_A_team_id, v_B_team_id
    from games g
             join ODDS O on O.GAME_ID = g.GAME_ID
    where O.ODD_ID = :new.ODD_ID;

--     select probability to win depending on odd type
    select case v_odd_type
               when 1 then A_WIN_CHANCE
               when 2 then DRAW_CHANCE
               when 3 then B_WIN_CHANCE end
    into v_probability
    from PROBABILITY_B
    where A_TEAM_ID = v_A_team_id and B_TEAM_ID = v_B_team_id
       or B_TEAM_ID = v_A_team_id and A_TEAM_ID = v_B_team_id;

    --     display data
--     DBMS_OUTPUT.PUT_LINE('date: ' || v_bet_date);
--     DBMS_OUTPUT.PUT_LINE('value: ' || v_odd_value);
--     DBMS_OUTPUT.PUT_LINE('prob: ' || v_probability);
end;
/

create trigger M_UPDATE_ODDS
    after insert
    on BETS
    for each row
declare
    v_game_id           games.game_id%type;
    v_sum_on_one_game   CALC_TOTAL.PLACED_TOTAL%type;
    v_odd_type_id       odd_type.odd_type_id%type;
    v_total_prize       calc_type_game.result_prize%type;
    v_total_match_prize calc_type_game.placed%type;
    v_max_prize         CALC_TOTAL.MAX_PRIZE%type;
begin
    
    --  get game_id and odd_type_id of bet odd
    select game_id, odd_type_id
    into v_game_id, v_odd_type_id
    from odds
    where odd_id = :new.odd_id;
    --
--  get total prize for the game_id nad odd_type
    select PLACED_TOTAL
    into v_sum_on_one_game
    from CALC_TOTAL
    where GAME_ID = v_game_id;
    --
--  get total sum placed on the game on the same result
    select result_prize
    into v_total_prize
    from CALC_TYPE_GAME
    where game_id = v_game_id
      and odd_type_id = v_odd_type_id;
    --
--     get max prize on the game
    select MAX_PRIZE
    into v_max_prize
    from CALC_TOTAL
    where GAME_ID = v_game_id;
    --
--  the amount of a bet on a game result exceeds € 100
    if :new.money_placed > 100 or

        --the amount of a bet on a result of the game is greater than 2% of the total amount bet on that result.
       :new.money_placed > v_sum_on_one_game * 0.02 or

        --total Prize on match result > Total Max Prize Match
       v_total_prize >= v_total_match_prize then

        DBMS_OUTPUT.PUT_LINE('(!) recalculation');
        ODD_CTRL.RECALCULATE_ODD(v_game_id);
--             
    else
        DBMS_OUTPUT.PUT_LINE('(x) stays');
    end if;
end;
/

create trigger P1_CALC_TYPE
    before insert
    on BETS
    for each row
declare
    v_game_id     games.GAME_ID%type;
    v_odd_type_id odds.odd_type_id%type;
    v_calc_id     number := 0;
--             operands
    v_count       number := 0;
--             values
    v_odd_value   number;
begin
    --         get game_id of bet and odd value
    select GAMES.GAME_ID, O2.VALUE, O2.ODD_TYPE_ID
    into v_game_id, v_odd_value, v_odd_type_id
    from GAMES
             join ODDS O2 on GAMES.GAME_ID = O2.GAME_ID
    where O2.ODD_ID = :new.odd_id;

    --         check if record of current bet game exists
    select count(*)
    into v_count
    from CALC_TYPE_GAME
             join GAMES G on CALC_TYPE_GAME.GAME_ID = G.GAME_ID
             join ODDS O on G.GAME_ID = O.GAME_ID
    where O.ODD_ID = :new.odd_id
      and CALC_TYPE_GAME.ODD_TYPE_ID = v_odd_type_id;
    --
--         if not, create new record
    if v_count = 0 then

        select coalesce(max(calc_id), 0)
        into v_calc_id
        from calc_type_game;
        v_calc_id := v_calc_id + 1;

        insert into CALC_TYPE_GAME values (v_calc_id, v_game_id, v_odd_type_id, 0, 0);
    end if;

    update CALC_TYPE_GAME
    set PLACED       = PLACED + :new.money_placed,
        RESULT_PRIZE = RESULT_PRIZE + (:new.money_placed * v_odd_value),

        --         max prize is total money placed on odd * this odd_value
        ODD_TYPE_ID  = v_odd_type_id
    where GAME_ID = v_game_id
      and ODD_TYPE_ID = v_odd_type_id;

end;
/

create trigger P2_CALC_TOTAL
    after insert
    on BETS
    for each row
declare

    v_game_id   games.GAME_ID%type ;
    v_count     number := 0;
    v_odd_value number;
begin
    --         get game_id of bet and odd value
    select GAMES.GAME_ID, O2.VALUE
    into v_game_id, v_odd_value
    from GAMES
             join ODDS O2 on GAMES.GAME_ID = O2.GAME_ID
    where O2.ODD_ID = :new.odd_id;

--         check if record of current bet game exists
    select count(*)
    into v_count
    from CALC_TOTAL
             join GAMES G on CALC_TOTAL.GAME_ID = G.GAME_ID
             join ODDS O on G.GAME_ID = O.GAME_ID
    where O.ODD_ID = :new.odd_id;

--         if not, create new record
    if v_count = 0 then
        insert into CALC_TOTAL values (v_game_id, 0, 0);
    end if;

    update CALC_TOTAL
    set PLACED_TOTAL = PLACED_TOTAL + :new.money_placed,
        MAX_PRIZE    = MAX_PRIZE + (:new.money_placed * 0.7);
    --         max prize is 70% of total money placed on odd

end;
/

--GAMES TABLE

create trigger T_GAME_DELETE
    before delete
    on GAMES
    for each row
declare
--     
    cursor c_odds is
        select *
        from ODDS
        where ODDS.GAME_ID = :old.game_id;
begin
    for odd in c_odds
        loop
            ARCHIVES.ARCHIVE_ODD_DEL(odd.ODD_ID);
        end loop;
    --     PAYOUTS_CTRL.CALCULATE_PAYOUT(:old.game_id);
--     
end;
/

create trigger T_GAME_INSERT_NEW_ODD
    after insert
    on GAMES
    for each row
begin
    ODD_CTRL.CALCULATE_NEW_ODD_B(:NEW.game_id,
                                 :NEW.A_team_id,
                                 :NEW.B_team_id);
    --
end;
/


--PAYMENTS TABLE

create trigger J_UPDATE_PAYMENTS_BALANCE
    after insert
    on PAYOUTS
    for each row
declare
begin
    update CLIENTS set BALANCE = BALANCE + :new.money where CLIENT_ID = :new.client_id;
end;
/

