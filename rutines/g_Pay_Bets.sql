create procedure G_PAY_BETS(vIdGame number) is

    v_count            number;
    v_id               number := 0;
    v_final            float  := 0;
    v_game             history_games%rowtype;
    v_odd_type_id      odds.odd_type_id%type;
    v_goals_difference number := 0;
--         get all bets placed on that game
    cursor c_bets is
        select b.*
        from bets b,
             history_odds o
        where b.odd_id = o.odd_id
          and o.game_id = vIdGame;
begin

    --     count whether there is any game of that game_id
    select count(GAME_ID)
    into v_count
    from (select GAME_ID
          from GAMES
          union
          select GAME_ID
          from history_games)
    where GAME_ID = vIdGame;

    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_game);
    end if;

    --         count whether there are any prized paid out for that game
    select count(*)
    into v_count
    from PAYOUTS p
             join BETS b
                  on b.BET_ID = p.BET_ID
             join HISTORY_ODDS HO on b.ODD_ID = HO.ODD_ID
    where HO.GAME_ID = vIdGame;

    if v_count > 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.prizes_paid);
    end if;

    --     check if game has finished - it is moved to history_games table
    select count(*)
    into v_count
    from games
    where GAME_ID = vIdGame;

    if v_count > 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.game_not_over);
    else
        select * into v_game from HISTORY_GAMES where GAME_ID = vIdGame;
        v_goals_difference := v_game.A_goals - v_game.B_goals;
    end if;

--     pay for winning bets
    for record in c_bets
        loop
            select o.ODD_TYPE_ID
            into v_odd_type_id
            from history_odds o
            where o.ODD_ID = record.ODD_ID;

            if
                    (v_goals_difference > 0 and v_odd_type_id = 1)
                    or
                    (v_goals_difference = 0 and v_odd_type_id = 2)
                    or
                    (v_goals_difference < 0 and v_odd_type_id = 3)
            then
                select coalesce(max(payout_id), 0)
                into v_id
                from payouts;
                v_id := v_id + 1;

                select o.value
                into v_final
                from history_odds o
                where o.odd_id = record.odd_id;

                v_final := v_final * record.money_placed;
                insert into payouts
                values (v_id, v_final, sysdate, record.client_id, record.bet_id);
                DBMS_OUTPUT.PUT_LINE('Inserting payout of value ' || v_final || ' for bet ' || record.bet_id);
            else
                DBMS_OUTPUT.PUT_LINE('Bet ' || record.BET_ID || ' lost. Bet type: ' || v_odd_type_id);
            end if;
        end loop;
end;
/

