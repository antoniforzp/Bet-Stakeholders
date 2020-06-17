create procedure I_PLACE_BET(vIdUser CLIENTS.CLIENT_ID%type,
                             vIdGame GAMES.GAME_ID%type,
                             vIdOddType ODDS.ODD_ID%type,
                             value BETS.MONEY_PLACED%TYPE) as

    v_match_date games.match_date%type;
    v_count      number;
    v_interval   number;
    v_max_bet_id bets.bet_id%type;
    v_odd_id     bets.odd_id%type;
begin

    --     check if user exists in database
    select count(*) into v_count from CLIENTS where CLIENT_ID = vIdUser;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_bettor);
    end if;

-- check if game has not finished, is in games table
    select count(*) into v_count from GAMES where GAME_ID = vIdGame;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_game);
    end if;

--     check type of odd
    select count(*) into v_count from ODD_TYPE where ODD_TYPE_ID = vIdOddType;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.invalid_bet_type);
    end if;

--     check minimal bet (1 euro)
    if value < 1 and value >= 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_money);
    end if;

    --     check negative bet
    if value < 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.negative_bet);
    end if;

--     check date whether bet time fits 15 min before start of the game
    select MATCH_DATE
    into v_match_date
    from GAMES
    where GAME_ID = vIdGame;

    select extract(minute from diff) minutes
    into v_interval
    from (select systimestamp - v_match_date diff
          from dual);

    DBMS_OUTPUT.PUT_LINE('remaining: ' || (-1) * v_interval || ' min');

--     shift match date -15 min to check if bet date does not exceed it
    if v_interval >= -15 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.game_closed);
    end if;

    --     INSERTING BET
--     get odd id by game_id and odd_type_id
    select ODD_ID
    into v_odd_id
    from ODDS
    where GAME_ID = vIdGame
      and ODD_TYPE_ID = vIdOddType;

--     get max bet id
    select coalesce(max(BET_ID), 0)
    into v_max_bet_id
    from bets;
    v_max_bet_id := v_max_bet_id + 1;

    DBMS_OUTPUT.PUT_LINE(v_max_bet_id);
    --     insert into BETS(BET_ID, CLIENT_ID, ODD_ID, MONEY_PLACED, BET_DATE)
--     values (v_max_bet_id, vIdUser, v_odd_id, value, sysdate);

--     lack of data according to L_FILL_BET trigger requirements
    insert into BETS(BET_ID, CLIENT_ID, ODD_ID, MONEY_PLACED, BET_DATE)
    values (v_max_bet_id, vIdUser, v_odd_id, value, null);
end;
/

