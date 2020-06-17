create PACKAGE BODY ARCHIVES AS
    procedure archive_game(p_game_id games.game_id%type,
                           p_A_score number,
                           p_B_score number) AS

        v_game_old games%rowtype;

    begin

        --         get game to be archived
        select GAME_ID,
               PHASE_ID,
               A_TEAM_ID,
               B_TEAM_ID,
               MATCH_DATE,
               STADIUM
        into v_game_old
        from games
        where game_id = p_game_id;

        insert into history_games
        values (v_game_old.GAME_ID,
                v_game_old.PHASE_ID,
                v_game_old.A_TEAM_ID,
                v_game_old.B_TEAM_ID,
                v_game_old.MATCH_DATE,
                v_game_old.STADIUM,
                p_A_score,
                p_B_score);

        HISTORY_COMPARISON_CTRL.MATCH_COMPARISON(p_game_id);
        TEAM_STATISTICS_CTRL.CALCULATE_TEAM_STATS(p_game_id, p_A_score, p_B_score);
        PROBABILITY_CTRL.RE_PROBABILITY_A(v_game_old.A_TEAM_ID, v_game_old.B_TEAM_ID);
        PROBABILITY_CTRL.RE_PROBABILITY_B(v_game_old.A_TEAM_ID, v_game_old.B_TEAM_ID);

    exception
        when NO_DATA_FOUND then
            DBMS_OUTPUT.PUT_LINE('match not found');

    end archive_game;

    procedure archive_game_del(p_game_id games.game_id%type,
                               p_A_score number,
                               p_B_score number) AS
    begin
        archive_game(p_game_id, p_A_score, p_B_score);
        delete from games where game_id = p_game_id;
    end archive_game_del;

    procedure archive_odd(p_odd_id odds.odd_id%type) as
        v_odd_to_archive odds%rowtype;
    begin
        select *
        into v_odd_to_archive
        from ODDS
        where ODD_ID = p_odd_id;

        DBMS_OUTPUT.PUT_LINE('archived odd: ' || p_odd_id);
        insert into history_odds
        values (v_odd_to_archive.odd_id, v_odd_to_archive.game_id, v_odd_to_archive.odd_type_id, v_odd_to_archive.value,
                v_odd_to_archive.odd_date);
    exception
        when NO_DATA_FOUND then
            DBMS_OUTPUT.PUT_LINE('odd not found: ' || p_odd_id);
    end archive_odd;

    procedure archive_odd_del(p_odd_id odds.odd_id%type) as
    begin
        archive_odd(p_odd_id);
        delete from ODDS where ODD_ID = p_odd_id;
    end archive_odd_del;

    procedure archive_bet(p_bet_id BETS.BET_ID%type) is
        v_old_bet bets%rowtype;
    begin
        select *
        into v_old_bet
        from BETS
        where BET_ID = p_bet_id;

        insert into HISTORY_BETS
        values (v_old_bet.BET_ID, v_old_bet.CLIENT_ID, v_old_bet.ODD_ID, v_old_bet.MONEY_PLACED, v_old_bet.BET_DATE);
    end;

    procedure archive_bet_del(p_bet_id BETS.BET_ID%type) is
    begin
        archive_bet(p_bet_id);
        delete from bets where BET_ID = p_bet_id;
    end;
end;
/

create package body bet_ctrl is

    procedure decide_recalculation(p_odd_id bets.odd_id%type,
                                   p_money_placed bets.money_placed%type) is

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
        where odd_id = p_odd_id;
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
        if p_money_placed > 100 or

            --the amount of a bet on a result of the game is greater than 2% of the total amount bet on that result.
           p_money_placed > v_sum_on_one_game * 0.02 or

            --total Prize on match result > Total Max Prize Match
           v_total_prize >= v_total_match_prize then

            DBMS_OUTPUT.PUT_LINE('(!) recalculation');
            ODD_CTRL.RECALCULATE_ODD(v_game_id);
--             
        else
            DBMS_OUTPUT.PUT_LINE('(x) stays');
        end if;
    end;

    procedure decide_recalculation_all is

        cursor c_bets is
            select *
            from bets;

    begin
        for record in c_bets
            loop
                DBMS_OUTPUT.PUT_LINE('bet: ' || record.BET_ID);
                decide_recalculation(record.ODD_ID, record.MONEY_PLACED);
            end loop;
    end;
end;
/

create package body CALC_TOTAL_CTRL is

    procedure add_game_calc_total(p_odd_id bets.ODD_ID%type,
                                  p_money_placed bets.money_placed%type) is
        v_game_id   games.GAME_ID%type ;
        v_count     number := 0;
        v_odd_value number;
    begin
        --         get game_id of bet and odd value
        select GAMES.GAME_ID, O2.VALUE
        into v_game_id, v_odd_value
        from GAMES
                 join ODDS O2 on GAMES.GAME_ID = O2.GAME_ID
        where O2.ODD_ID = p_odd_id;

--         check if record of current bet game exists
        select count(*)
        into v_count
        from CALC_TOTAL
                 join GAMES G on CALC_TOTAL.GAME_ID = G.GAME_ID
                 join ODDS O on G.GAME_ID = O.GAME_ID
        where O.ODD_ID = p_odd_id;

--         if not, create new record
        if v_count = 0 then
            insert into CALC_TOTAL values (v_game_id, 0, 0);
        end if;

        update CALC_TOTAL
        set PLACED_TOTAL = PLACED_TOTAL + p_money_placed,
            MAX_PRIZE    = MAX_PRIZE + (p_money_placed * 0.7);
        --         max prize is 70% of total money placed on odd

    end add_game_calc_total;

    procedure re_game_calc_total_all is
        cursor c_bets is
            select *
            from bets;
    begin
        delete from CALC_TOTAL;
        for bet in c_bets
            loop
                add_game_calc_total(bet.ODD_ID, bet.MONEY_PLACED);
            end loop;
    end re_game_calc_total_all;
end;
/

create package body CALC_TYPE_GAME_CTRL is

    procedure add_game_type_calc_total(p_odd_id bets.ODD_ID%type,
                                       p_money_placed bets.money_placed%type) is
        v_game_id     games.GAME_ID%type;
        v_odd_type_id odds.odd_type_id%type ;
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
        where O2.ODD_ID = p_odd_id;

        --         check if record of current bet game exists
        select count(*)
        into v_count
        from CALC_TYPE_GAME
                 join GAMES G on CALC_TYPE_GAME.GAME_ID = G.GAME_ID
                 join ODDS O on G.GAME_ID = O.GAME_ID
        where O.ODD_ID = p_odd_id
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
        set PLACED       = PLACED + p_money_placed,
            RESULT_PRIZE = RESULT_PRIZE + (p_money_placed * v_odd_value),
            --         max prize is total money placed on odd * this odd_value
            ODD_TYPE_ID  = v_odd_type_id
        where GAME_ID = v_game_id
          and ODD_TYPE_ID = v_odd_type_id;

    end add_game_type_calc_total;


    procedure re_game_type_calc_total_all is
        cursor c_bets is
            select *
            from bets;
    begin
        delete from CALC_TYPE_GAME;
        for bet in c_bets
            loop
                add_game_type_calc_total(bet.ODD_ID, bet.MONEY_PLACED);
            end loop;

    end re_game_type_calc_total_all;

end CALC_TYPE_GAME_CTRL;
/

create PACKAGE BODY EXCEPTIONS AS
    --
    function get_message(p_exception_code number) return varchar2 is
    begin
        if p_exception_code = -20501 then
            return 'Team does not exist.';
        elsif p_exception_code = -20502 then
            return 'Game does not exist.';
        elsif p_exception_code = -20503 then
            return 'Bettor does not exist.';
        elsif p_exception_code = -20504 then
            return 'Bet does not exist.';
        elsif p_exception_code = -20505 then
            return 'Competition does not exist.';
        elsif p_exception_code = -20506 then
            return 'Invalid bet type.';
        elsif p_exception_code = -20507 then
            return 'Invalid bet type for this game.';
        elsif p_exception_code = -20508 then
            return 'Insufficient balance for the bet.';
        elsif p_exception_code = -20509 then
            return 'The game no longer accepts bets.';
        elsif p_exception_code = -20510 then
            return 'Invalid number of years (> 0)';
        elsif p_exception_code = -20511 then
            return 'There is no phase from this competition.';
        elsif p_exception_code = -20512 then
            return 'There is no phase for this competition on that date.';
        elsif p_exception_code = -20513 then
            return 'Game already registered. There is already a game between these 2 teams on that journey.';
        elsif p_exception_code = -20514 then
            return 'There are already registered odds for this game.';
        elsif p_exception_code = -20515 then
            return 'Invalid event type.';
        elsif p_exception_code = -20516 then
            return 'The bet amount must be positive (minimum 1).';
        elsif p_exception_code = -20517 then
            return 'The game is not over yet. Bets cannot yet be settled.';
        elsif p_exception_code = -20518 then
            return 'Prizes for winning bets have already been registered and paid for.';
        elsif p_exception_code = -20519 then
            return 'Charge must be over zero';
        else
            return 'message not found';
        end if;
    end get_message;

    procedure raise_exception(p_exception_code number) is
    begin
        RAISE_APPLICATION_ERROR(p_exception_code, get_message(p_exception_code));
    end;
end;
/

create package body HISTORY_COMPARISON_CTRL as

    function check_match_result(A_score in number,
                                B_score in number) return varchar2 AS

        v_result varchar(1);

    begin
        if A_score > B_score then
            v_result := 'A';
        elsif A_score < B_score then
            v_result := 'B';
        else
            v_result := '0';
        end if;
        return v_result;
    end check_match_result;

    procedure check_add_record(p_A_team_id history_games.A_team_id%type,
                               p_B_team_id history_games.B_team_id%type) is
        v_count number := 0;

    begin
        select count(*)
        into v_count
        from HISTORY_COMPARISON
        where A_TEAM_ID = p_A_team_id and
              B_TEAM_ID = p_B_team_id
           or B_TEAM_ID = p_A_team_id and
              A_TEAM_ID = p_B_team_id;

        if (v_count <= 0) then
            insert into HISTORY_COMPARISON values (p_A_team_id, p_B_team_id, 0, 0, 0, 0);
        end if;

    end check_add_record;

    procedure clean_records is
    begin
        update HISTORY_COMPARISON
        set MATCHES_AMOUNT = 0,
            A_WON          = 0,
            DRAW           = 0,
            B_WON          = 0;
    end clean_records;

    procedure match_comparison(p_history_game_id games.game_id%type) is

        v_history_game history_games%rowtype;
--         order flags
        v_A_team_id    history_games.A_team_id%type;
        v_B_team_id    history_games.B_team_id%type;
--             results
        v_result       varchar2(1);
        v_A_won        number := 0;
        v_draw         number := 0;
        v_B_won        number := 0;

    begin
        --         get match by id
        select *
        into v_history_game
        from HISTORY_GAMES
        where GAME_ID = p_history_game_id;

        check_add_record(v_history_game.A_TEAM_ID, v_history_game.B_TEAM_ID);

        select A_TEAM_ID, B_TEAM_ID
        into v_A_team_id, v_B_team_id
        from HISTORY_COMPARISON
        where A_TEAM_ID = v_history_game.A_TEAM_ID and
              B_TEAM_ID = v_history_game.B_TEAM_ID
           or B_TEAM_ID = v_history_game.A_TEAM_ID and
              A_TEAM_ID = v_history_game.B_TEAM_ID;

--         depending on order set result
        if v_history_game.A_TEAM_ID = v_A_team_id and
           v_history_game.B_TEAM_ID = v_B_team_id then

            v_result := check_match_result(v_history_game.A_GOALS, v_history_game.B_GOALS);

        elsif v_history_game.A_TEAM_ID = v_B_team_id and
              v_history_game.B_TEAM_ID = v_A_team_id then

            v_result := check_match_result(v_history_game.B_GOALS, v_history_game.A_GOALS);
        end if;

        if v_result = 'A' then
            v_A_won := 1;
        elsif v_result = 'B' then
            v_B_won := 1;
        else
            v_draw := 1;
        end if;

        update HISTORY_COMPARISON
        set A_WON          = A_WON + v_A_won,
            DRAW           = DRAW + v_draw,
            B_WON          = B_WON + v_B_won,
            MATCHES_AMOUNT = MATCHES_AMOUNT + 1
        where A_TEAM_ID = v_A_team_id
          and B_TEAM_ID = v_B_team_id;

    end match_comparison;

    procedure re_match_comparison_all is

        cursor c_all_history_games is
            select *
            from HISTORY_GAMES;

    begin
        clean_records;
        for match in c_all_history_games
            loop
                match_comparison(match.GAME_ID);
            end loop;

    end re_match_comparison_all;

end HISTORY_COMPARISON_CTRL;
/

create PACKAGE BODY ODD_CTRL AS

    procedure calculate_new_odd_A(p_game_id games.GAME_ID%type,
                                  p_A_team_id games.A_team_id%type,
                                  p_B_team_id games.B_team_id%type) is

        v_count        number;
        v_id           number := 1;
--         prevention flags
        v_margin       float  := 0.3;
        v_min_chance   float  := 50; -- sometimes chance from probA is 0, to avoid calculation problems we assume minimal chance to 50%
        v_min_odd      float  := 1.01;
--             final odds
        v_A_win        float  := 0;
        v_draw         float  := 0;
        v_B_win        float  := 0;
        --             chances
        v_A_win_chance probability_B.A_WIN_CHANCE%type ;
        v_draw_chance  probability_B.DRAW_CHANCE%type ;
        v_B_win_chance probability_B.B_WIN_CHANCE%type ;
    begin

        select count(*)
        into v_count
        from PROBABILITY_A
        where A_TEAM_ID = p_A_team_id and
              B_TEAM_ID = p_B_team_id
           or A_TEAM_ID = p_B_team_id and
              B_TEAM_ID = p_A_team_id;

--         if pair of team does not have calculated probability
        if v_count = 0 then
            v_A_win_chance := 0;
            v_draw_chance := 0;
            v_B_win_chance := 0;
        else
            --         get probability A record of pair of teams playing in following game
            select A_WIN_CHANCE, DRAW_CHANCE, B_WIN_CHANCE
            into v_A_win_chance, v_draw_chance, v_B_win_chance
            from probability_B
            where A_TEAM_ID = p_A_team_id and
                  B_TEAM_ID = p_B_team_id
               or A_TEAM_ID = p_B_team_id and
                  B_TEAM_ID = p_A_team_id;
        end if;


--         calculate win A odd according to formula
        if v_A_win_chance = 0 then
            v_A_win := (1 / (v_min_chance / 100)) * (1 - v_margin);
        else
            v_A_win := (1 / (v_A_win_chance / 100)) * (1 - v_margin);
        end if;

--         calculate draw odd according to formula
        if v_draw_chance = 0 then
            v_draw := (1 / (v_min_chance / 100)) * (1 - v_margin);
        else
            v_draw := (1 / (v_draw_chance / 100)) * (1 - v_margin);
        end if;

--         calculate win B odd according to formula
        if v_B_win_chance = 0 then
            v_B_win := (1 / (v_min_chance / 100)) * (1 - v_margin);
        else
            v_B_win := (1 / (v_B_win_chance / 100)) * (1 - v_margin);
        end if;


--         prevent odds not to be below 1
        if v_A_win <= 1 then
            v_A_win := v_min_odd;
        end if;

        if v_draw <= 1 then
            v_draw := v_min_odd;
        end if;

        if v_B_win <= 1 then
            v_B_win := v_min_odd;
        end if;

--         find max id of odds
        select coalesce(max(odd_id), 0)
        into v_id
        from odds;

        v_id := v_id + 1;

--         win A odd
        insert into odds values (v_id, p_game_id, 1, v_A_win, sysdate);
        v_id := v_id + 1;

--         draw odd
        insert into odds values (v_id, p_game_id, 2, v_draw, sysdate);
        v_id := v_id + 1;

--         win B odd
        insert into odds values (v_id, p_game_id, 3, v_B_win, sysdate);

    end calculate_new_odd_A;

    procedure calculate_odd_A_all is
        cursor c_games is
            select *
            from games;
    begin
        delete from odds;
        for record in c_games
            loop
                calculate_new_odd_A(record.game_id,
                                    record.A_TEAM_ID,
                                    record.B_TEAM_ID);
            end loop;
    end calculate_odd_A_all;

    procedure calculate_new_odd_B(p_game_id games.GAME_ID%type,
                                  p_A_team_id games.A_team_id%type,
                                  p_B_team_id games.B_team_id%type) is

        v_count        number;
        v_id           number := 1;
--         prevention flags
        v_margin       float  := 0.3;
        v_min_chance   float  := 50; -- sometimes chance from probA is 0, to avoid calculation problems we assume minimal chance to 50%
        v_min_odd      float  := 1.01;
--             final odds
        v_A_win        float  := 0;
        v_draw         float  := 0;
        v_B_win        float  := 0;
--             chances
        v_A_win_chance probability_B.A_WIN_CHANCE%type ;
        v_draw_chance  probability_B.DRAW_CHANCE%type ;
        v_B_win_chance probability_B.B_WIN_CHANCE%type ;
    begin

        select count(*)
        into v_count
        from PROBABILITY_B
        where A_TEAM_ID = p_A_team_id and
              B_TEAM_ID = p_B_team_id
           or A_TEAM_ID = p_B_team_id and
              B_TEAM_ID = p_A_team_id;

--         if pair of team does not have calculated probability
        if v_count = 0 then
            v_A_win_chance := 0;
            v_draw_chance := 0;
            v_B_win_chance := 0;
        else
            --         get probability A record of pair of teams playing in following game
            select A_WIN_CHANCE, DRAW_CHANCE, B_WIN_CHANCE
            into v_A_win_chance, v_draw_chance, v_B_win_chance
            from probability_B
            where A_TEAM_ID = p_A_team_id and
                  B_TEAM_ID = p_B_team_id
               or A_TEAM_ID = p_B_team_id and
                  B_TEAM_ID = p_A_team_id;
        end if;


--         calculate win A odd according to formula
        if v_A_win_chance = 0 then
            v_A_win := (1 / (v_min_chance / 100)) * (1 - v_margin);
        else
            v_A_win := (1 / (v_A_win_chance / 100)) * (1 - v_margin);
        end if;

--         calculate draw odd according to formula
        if v_draw_chance = 0 then
            v_draw := (1 / (v_min_chance / 100)) * (1 - v_margin);
        else
            v_draw := (1 / (v_draw_chance / 100)) * (1 - v_margin);
        end if;

--         calculate win B odd according to formula
        if v_B_win_chance = 0 then
            v_B_win := (1 / (v_min_chance / 100)) * (1 - v_margin);
        else
            v_B_win := (1 / (v_B_win_chance / 100)) * (1 - v_margin);
        end if;


--         prevent odds not to be below 1
        if v_A_win <= 1 then
            v_A_win := v_min_odd;
        end if;

        if v_draw <= 1 then
            v_draw := v_min_odd;
        end if;

        if v_B_win <= 1 then
            v_B_win := v_min_odd;
        end if;

--         find max id of odds
        select coalesce(max(odd_id), 0)
        into v_id
        from odds;
        v_id := v_id + 1;

--         win A odd
        insert into odds values (v_id, p_game_id, 1, v_A_win, sysdate);
        v_id := v_id + 1;

--         draw odd
        insert into odds values (v_id, p_game_id, 2, v_draw, sysdate);
        v_id := v_id + 1;

--         win B odd
        insert into odds values (v_id, p_game_id, 3, v_B_win, sysdate);

    end calculate_new_odd_B;

    procedure calculate_odd_B_all is
        cursor c_games is
            select *
            from games;
    begin
        delete from odds;
        for record in c_games
            loop
                calculate_new_odd_B(record.GAME_ID,
                                    record.A_TEAM_ID,
                                    record.B_TEAM_ID);
            end loop;
    end calculate_odd_B_all;

    procedure recalculate_odd(p_game_id odds.game_id%type) is

        v_count        number;
        v_new_odd_id   number;
        v_final        float := 0;
        v_result_final float := 0;
        v_min          float := 0;
        v_result_prize float := 0;
        v_max_prize    float := 0;
        v_min_odd      float := 1.01;
        v_max_odd      float := 9.99;
        cursor c_odds_game is
            select *
            from odds
            where GAME_ID = p_game_id;

    begin
        for odd in c_odds_game
            loop
                select count(*)
                into v_count
                from ODDS
                where ODD_ID = odd.odd_id;

                if v_count = 0 then
                    DBMS_OUTPUT.PUT_LINE('odd not found: ' || odd.odd_id);
                else

--                     check if odd has record in calc type game
                    select count(RESULT_PRIZE)
                    into v_count
                    from CALC_TYPE_GAME
                    where ODD_TYPE_ID = odd.ODD_TYPE_ID
                      and GAME_ID = p_game_id;

                    if v_count = 0 then
                        DBMS_OUTPUT.PUT_LINE('no calc type found');
                        v_result_prize := 0;
                    else
--                     take result_prize of game_id of curr_odd_type
                        select RESULT_PRIZE
                        into v_result_prize
                        from CALC_TYPE_GAME
                        where ODD_TYPE_ID = odd.ODD_TYPE_ID
                          and GAME_ID = p_game_id;
                    end if;

--                 take max_prize of the game_id
                    select MAX_PRIZE
                    into v_max_prize
                    from CALC_TOTAL
                    where GAME_ID = p_game_id;

                    if v_result_prize < v_max_prize and v_result_prize > 0 then
                        v_min := v_result_prize;
                    else
                        v_min := v_max_prize;
                    end if;

--                 if there is not total prize select max_prize
                    if v_min = 0 then
                        select t.max_prize
                        into v_min
                        from calc_total t
                        where t.game_id = p_game_id;
                    end if;

                    select sum(RESULT_PRIZE)
                    into v_result_final
                    from CALC_TYPE_GAME
                    where game_id = p_game_id;

--                 calculate new odd
                    v_final := v_result_final / v_min;

                    if v_final <= 1 then
                        v_final := v_min_odd;
                    elsif v_final >= 10 then
                        v_final := v_max_odd;
                    end if;

--                 prepare new odd to be inserted
                    select coalesce(max(odd_id), 0)
                    into v_new_odd_id
                    from odds;
                    v_new_odd_id := v_new_odd_id + 1;

--                     watch out those sneaky bustards
                    insert into odds values (v_new_odd_id, p_game_id, odd.ODD_TYPE_ID, v_final, sysdate);
                    ARCHIVES.ARCHIVE_ODD_DEL(odd.ODD_ID);

                    DBMS_OUTPUT.PUT_LINE('old odd: ' || odd.ODD_ID || ' v: ' || odd.VALUE);
                    DBMS_OUTPUT.PUT_LINE('new odd: ' || v_new_odd_id || ' v: ' || v_final);
                    DBMS_OUTPUT.PUT_LINE('----------');

                end if;
            end loop;

    end recalculate_odd;

    procedure
        recalculate_all_odds is
        cursor c_games is
            select *
            from games;
    begin
        for record in c_games
            loop
                recalculate_odd(record.game_id);
            end loop;
    end recalculate_all_odds;

--         
    procedure
        recalculate_odd2(p_game_id odds.game_id%type) is
        v_count      number;
        v_new_odd_id number;
        v_final      float := 0;
        cursor c_odds_game is
            select *
            from odds
            where GAME_ID = p_game_id;

    begin
        for odd in c_odds_game
            loop
                select count(*)
                into v_count
                from ODDS
                where ODD_ID = odd.odd_id;

                if v_count = 0 then
                    DBMS_OUTPUT.PUT_LINE('odd not found: ' || odd.odd_id);
                else
                    --                     check if odd has record in calc type game

--                 calculate new odd
                    v_final := get_result(p_game_id);

--                 prepare new odd to be inserted
                    select coalesce(max(odd_id), 0)
                    into v_new_odd_id
                    from odds;
                    v_new_odd_id := v_new_odd_id + 1;

                    --                     watch out those sneaky bustards
--                     insert into odds values (v_new_odd_id, p_game_id, odd.ODD_TYPE_ID, v_final, sysdate);
--                     ARCHIVES.ARCHIVE_ODD_DEL(odd.ODD_ID);

                    DBMS_OUTPUT.PUT_LINE('old odd: ' || odd.ODD_ID || ' v: ' || odd.VALUE);
                    DBMS_OUTPUT.PUT_LINE('new odd: ' || v_new_odd_id || ' v: ' || v_final);
                    DBMS_OUTPUT.PUT_LINE('----------');

                end if;
            end loop;

    end recalculate_odd2;

    procedure
        recalculate_all_odds2 is
        cursor c_games is
            select *
            from games;
    begin
        for record in c_games
            loop
                recalculate_odd2(record.game_id);
            end loop;
    end recalculate_all_odds2;


    function
        get_result(p_game_id games.game_id%type)
        return number
        is
        v_count        number;
        v_result_prize float := 0;
        v_max_prize    float := 0;
        v_min          float := 0;
        v_partial      float := 0;
        v_final        float := 0;
        cursor c_odds is
            select *
            from odds
            where GAME_ID = p_game_id;
    begin
        for record in c_odds
            loop
                select count(RESULT_PRIZE)
                into v_count
                from CALC_TYPE_GAME
                where ODD_TYPE_ID = record.ODD_TYPE_ID
                  and GAME_ID = p_game_id;

                if v_count = 0 then
                    DBMS_OUTPUT.PUT_LINE('no calc type found');
                    v_result_prize := 0;
                else
--                     take result_prize of game_id of curr_odd_type
                    select RESULT_PRIZE
                    into v_result_prize
                    from CALC_TYPE_GAME
                    where ODD_TYPE_ID = record.ODD_TYPE_ID
                      and GAME_ID = p_game_id;
                end if;

--                 take max_prize of the game_id
                select MAX_PRIZE
                into v_max_prize
                from CALC_TOTAL
                where GAME_ID = p_game_id;

                if v_result_prize < v_max_prize and v_result_prize > 0 then
                    v_min := v_result_prize;
                else
                    v_min := v_max_prize;
                end if;

--                 if there is not total prize select max_prize
                if v_min = 0 then
                    select t.max_prize
                    into v_min
                    from calc_total t
                    where t.game_id = p_game_id;
                end if;

                v_partial := v_result_prize / v_min;
                v_final := v_final + v_partial;
            end loop;
        return v_final;
    end;
end;
/

create PACKAGE BODY PAYOUTS_CTRL AS

    procedure calculate_payout(p_game_id games.game_id%type) is

        v_id               number := 0;
        v_final            float  := 0;
        v_game             history_games%rowtype;
        v_odd_type_id      odds.odd_type_id%type;
        v_goals_difference number := 0;
        cursor c_bets is
            select b.*
            from bets b,
                 history_odds o
            where b.odd_id = o.odd_id
              and o.game_id = p_game_id;

    begin
        select * into v_game from HISTORY_GAMES where GAME_ID = p_game_id;
        v_goals_difference := v_game.A_goals - v_game.B_goals;


        for record in c_bets
            loop
                select o.ODD_TYPE_ID
                into v_odd_type_id
                from history_odds o
                where o.ODD_ID = record.ODD_ID;

                if (v_goals_difference > 0 and v_odd_type_id = 1) or (v_goals_difference = 0 and v_odd_type_id = 2) or
                   (v_goals_difference < 0 and v_odd_type_id = 3) then
                    select coalesce(max(payout_id), 0)
                    into v_id
                    from payouts;
                    v_id := v_id + 1;

                    select o.value
                    into v_final
                    from history_odds o
                    where o.odd_id = record.odd_id;

                    v_final := v_final * record.money_placed;
                    insert into payouts values (v_id, v_final, sysdate, record.client_id, record.bet_id);
                    DBMS_OUTPUT.PUT_LINE('Inserting payout of value ' || v_final || ' for bet ' || record.bet_id);

                end if;
            end loop;
    end calculate_payout;

    procedure
        recalculate_all_payouts is
        cursor c_bets is
            select *
            from HISTORY_GAMES;
    begin
        delete from payouts;
        for record in c_bets
            loop
                PAYOUTS_CTRL.CALCULATE_PAYOUT(record.game_id);
            end loop;
    end;
end;
/

create package body probability_ctrl as

    procedure clean_probability_A is
    begin
        update PROBABILITY_A
        set A_WIN_CHANCE = 0,
            DRAW_CHANCE  = 0,
            B_WIN_CHANCE = 0;
    end;

    procedure clean_probability_B is
    begin
        update PROBABILITY_B
        set A_WIN_CHANCE = 0,
            DRAW_CHANCE  = 0,
            B_WIN_CHANCE = 0;
    end;


    procedure re_probability_A(p_A_team_id history_comparison.A_team_id%type,
                               p_B_team_id history_comparison.B_team_id%type) is

        v_history_comparison history_comparison%rowtype;
        v_id                 number := 0;
        v_count              number := 0;
        v_A_win_prob         float  := 0;
        v_draw_prob          float  := 0;
        v_B_win_prob         float  := 0;

    begin
        --         get history comparison record concerning pair on team ids
        select *
        into v_history_comparison
        from HISTORY_COMPARISON
        where A_TEAM_ID = p_A_team_id
          and B_TEAM_ID = p_B_team_id;

--         calculate probabilities
        v_A_win_prob := (v_history_comparison.A_won / (v_history_comparison.matches_amount)) * 100;
        v_draw_prob := (v_history_comparison.draw / (v_history_comparison.matches_amount)) * 100;
        v_B_win_prob := (v_history_comparison.B_won / (v_history_comparison.matches_amount)) * 100;

--         check if record for probabilities exists
        select count(*)
        into v_count
        from probability_A
        where A_team_id = v_history_comparison.A_team_id
          and B_team_id = v_history_comparison.B_team_id;

        if v_count = 0 then

            --         get max id in table
            select max(PROB_A_ID)
            into v_id
            from PROBABILITY_A;

            if v_id is null then
                v_id := 0;
            else
                v_id := v_id + 1;
            end if;

            insert into probability_A
            values (v_id, v_history_comparison.A_team_id, v_history_comparison.B_team_id,
                    v_A_win_prob, v_draw_prob, v_B_win_prob);

        else
            update probability_A
            set A_win_chance = v_A_win_prob,
                draw_chance  = v_draw_prob,
                B_win_chance = v_B_win_prob
            where A_team_id = v_history_comparison.A_team_id
              and B_team_id = v_history_comparison.B_team_id;
        end if;
    end re_probability_A;

    procedure re_probability_A_all is

        cursor c_history_comparison is
            select *
            from history_comparison;

    begin
        clean_probability_A;
        for history_comparison in c_history_comparison
            loop
                re_probability_A(history_comparison.A_TEAM_ID, history_comparison.B_TEAM_ID);
            end loop;
    end re_probability_A_all;

    procedure re_probability_B(p_A_team_id history_comparison.A_team_id%type,
                               p_B_team_id history_comparison.B_team_id%type) is

        v_probability_A probability_A%rowtype;
        v_id            number := 0;
        v_count         number := 0;
        v_A_win         float  := 0;
        v_A_draw        float  := 0;
        v_A_lose        float  := 0;
        v_B_win         float  := 0;
        v_B_draw        float  := 0;
        v_B_lose        float  := 0;
        v_final_A_win   float  := 0;
        v_final_draw    float  := 0;
        v_final_B_win   float  := 0;
--
        v_A_won_num     number;
        v_A_draw_num    number;
        v_A_lost_num    number;
        v_A_played      number;
--
        v_B_won_num     number;
        v_B_draw_num    number;
        v_B_lost_num    number;
        v_B_played      number;

    begin

        --         get team statistics record of A team
        select sum(WON), sum(DRAW), sum(LOST), sum(PLAYED)
        into v_A_won_num, v_A_draw_num, v_A_lost_num, v_A_played
        from TEAM_STATISTICS
        where team_id = p_A_team_id;

        --         get team statistics record of B team
        select sum(WON), sum(DRAW), sum(LOST), sum(PLAYED)
        into v_B_won_num, v_B_draw_num, v_B_lost_num, v_B_played
        from TEAM_STATISTICS
        where team_id = p_B_team_id;

        --         get probability A record concerning pair on team ids
        select *
        into v_probability_A
        from PROBABILITY_A
        where A_TEAM_ID = p_A_team_id
          and B_TEAM_ID = p_B_team_id;

--         calculate team A ratios
        v_A_win := (v_A_won_num / v_A_played) * 100;
        v_A_draw := (v_A_draw_num / v_A_played) * 100;
        v_A_lose := (v_A_lost_num / v_A_played) * 100;

--         calculate team B ratios
        v_B_win := (v_B_won_num / v_B_played) * 100;
        v_B_draw := (v_B_draw_num / v_B_played) * 100;
        v_B_lose := (v_B_lost_num / v_B_played) * 100;


--         calculate average of ratio A with probabilityA of A team
        v_A_win := (v_A_win + v_probability_A.A_win_chance) / 2;
        v_A_draw := (v_A_draw + v_probability_A.draw_chance) / 2;
        v_A_lose := (v_A_lose + v_probability_A.B_win_chance) / 2;

--         calculate average of ratio B with probabilityA of B team
        v_B_win := (v_B_win + v_probability_A.B_win_chance) / 2;
        v_B_draw := (v_B_draw + v_probability_A.draw_chance) / 2;
        v_B_lose := (v_B_lose + v_probability_A.A_win_chance) / 2;

--         calculate final average
        v_final_A_win := (v_A_win + v_B_lose) / 2;
        v_final_draw := (v_A_draw + v_B_draw) / 2;
        v_final_B_win := (v_B_win + v_A_lose) / 2;

--         check if record for probabilities exists
        select count(*)
        into v_count
        from probability_B
        where A_team_id = p_A_team_id
          and B_team_id = p_B_team_id;

        if v_count = 0 then

            --         get max id in table
            select max(PROB_A_ID)
            into v_id
            from PROBABILITY_A;

            if v_id is null then
                v_id := 0;
            else
                v_id := v_id + 1;
            end if;

            insert into probability_B
            values (p_A_team_id, p_B_team_id,
                    v_final_A_win, v_final_draw, v_final_B_win,
                    v_probability_A.PROB_A_ID);
        else
            update probability_B
            set A_win_chance = v_final_A_win,
                draw_chance  = v_final_draw,
                B_win_chance = v_final_B_win
            where A_team_id = p_A_team_id
              and B_team_id = p_B_team_id;
        end if;

    end re_probability_B;


    procedure re_probability_B_all is

        cursor c_history_comparison is
            select *
            from history_comparison;

    begin
        clean_probability_B;
        for history_comparison in c_history_comparison
            loop
                re_probability_B(history_comparison.A_TEAM_ID,
                                 history_comparison.B_TEAM_ID);
            end loop;
    end re_probability_B_all;
end probability_ctrl;
/

create package body random_generating is

    procedure generate_events_game(p_game_id history_games.game_id%type) is

        v_max_event_id      events.event_id%type;
        v_max_event_type_id EVENT_TYPE.EVENT_TYPE_ID%type;
        v_random            integer;
        v_random2           integer;
        v_A_team_id         history_games.A_team_id%type;
        v_B_team_id         history_games.A_team_id%type;
        v_curr_team_id      teams.team_id%type;
        v_A_score           number;
        v_B_score           number;

    begin

        --         get max event id
        select coalesce(max(event_id), 0)
        into v_max_event_id
        from EVENTS;

        --         get max event type id
        select max(event_type_id)
        into v_max_event_type_id
        from EVENT_TYPE
        where EVENT_TYPE_ID not in (13, 14);

--         get data from game
        select A_team_id, B_team_id, A_GOALS, B_GOALS
        into v_A_team_id, v_B_team_id, v_A_score, v_B_score
        from HISTORY_GAMES
        where game_id = p_game_id;

--         generate events according goals scored
        for i in 1..v_A_score
            loop
                v_max_event_id := v_max_event_id + 1;
                v_random := DBMS_RANDOM.VALUE(1, 90);
                insert into EVENTS values (v_max_event_id, 13, p_game_id, v_A_team_id, v_random);
--                 DBMS_OUTPUT.PUT_LINE(v_A_team_id || ' score');
            end loop;

        for i in 1..v_B_score
            loop
                v_max_event_id := v_max_event_id + 1;
                v_random := DBMS_RANDOM.VALUE(1, 90);
                insert into EVENTS values (v_max_event_id, 14, p_game_id, v_B_team_id, v_random);
--                 DBMS_OUTPUT.PUT_LINE(v_B_team_id || ' score');
            end loop;

--         how many events generate
        v_random := DBMS_RANDOM.VALUE(1, 20);
        for i in 1..v_random
            loop
                --         decide which team take
                v_random := DBMS_RANDOM.VALUE(1, 2);
                if v_random = 1 then
                    v_curr_team_id := v_A_team_id;
                else
                    v_curr_team_id := v_B_team_id;
                end if;

                v_max_event_id := v_max_event_id + 1;
                --                 decide which event take
                v_random := DBMS_RANDOM.VALUE(1, v_max_event_type_id);
--                 decide which match minute
                v_random2 := DBMS_RANDOM.VALUE(1, 90);
                insert into events values (v_max_event_id, v_random, p_game_id, v_curr_team_id, v_random2);
--                 DBMS_OUTPUT.PUT_LINE(v_curr_team_id || ' ' || v_random);
            end loop;


    end generate_events_game;

    procedure re_generate_events_game_all is
        cursor c_games is
            select *
            from HISTORY_GAMES;
    begin
        delete from events;
        for game in c_games
            loop
                generate_events_game(game.GAME_ID);
            end loop;
    end;

    function random_score(p_top integer)
        return integer
        is
    begin
        return DBMS_RANDOM.VALUE(0, p_top);
    end;

    procedure generate_bet(p_game_id games.game_id%type, p_odd_type odds.odd_type_id%type)
        is
        v_bet_id    bets.bet_id%type;
        v_client_id clients.client_id%type;
        v_odd_id    odds.odd_id%type;
    begin
        select coalesce(max(bet_id), 0) into v_bet_id from bets;
        v_bet_id := v_bet_id + 1;
        select coalesce(max(client_id), 1) into v_client_id from clients;
        v_client_id := random_score(v_client_id - 1) + 1;

        select odd_id
        into v_odd_id
        from odds
        where GAME_ID = p_game_id
          and ODD_TYPE_ID = p_odd_type;

        insert into bets
        values (v_bet_id, v_client_id, v_odd_id, random_score(299) + 1, sysdate);
    end;

    function get_random_team return teams.team_id%type is
        v_random  integer;
        v_rows    number;
        v_team_id teams.team_id%type;
    begin
        select count(*)
        into v_rows
        from TEAMS;

        v_random := DBMS_RANDOM.VALUE(1, v_rows);

        select TEAM_ID
        into v_team_id
        from (select a.*, max(TEAM_ID) over () as max_id
              from TEAMS a
              where ROWNUM < v_random
             )
        where TEAM_ID = max_id;

        return v_team_id;
    end;

    function get_random_team_no(p_team_id teams.team_id%type) return teams.team_id%type is
        v_random  integer;
        v_rows    number;
        v_team_id teams.team_id%type;
    begin
        select count(*)
        into v_rows
        from TEAMS;

        v_random := DBMS_RANDOM.VALUE(1, v_rows);

        select TEAM_ID
        into v_team_id
        from (select a.*, max(TEAM_ID) over () as max_pk
              from TEAMS a
              where ROWNUM < v_random
                and TEAM_ID != p_team_id
             )
        where TEAM_ID = max_pk;

        return v_team_id;
    end;
--
end;
/

create package body TEAM_STATISTICS_CTRL as

    --     adds empty records with 0 0 0 when team does not have it yet
    procedure check_add_record(p_history_game_id HISTORY_GAMES.GAME_ID%type) is

        v_count          number := 0;
        v_team_A_id      team_statistics.team_id%type;
        v_team_B_id      team_statistics.team_id%type;
        v_competition_id team_statistics.competition_id%type;

    begin
        select h.A_team_id, h.B_team_id, p.competition_id
        into v_team_A_id, v_team_B_id, v_competition_id
        from history_games h,
             phases p
        where h.phase_id = p.phase_id
          and h.game_id = p_history_game_id;

        --check if team A exists in table
        select count(*)
        into v_count
        from team_statistics
        where team_id = v_team_A_id
          and competition_id = v_competition_id;

        if v_count = 0 then
            insert into team_statistics values (v_team_A_id, v_competition_id, 0, 0, 0, 0);
        end if;

        --check if team B exists in table
        select count(*)
        into v_count
        from team_statistics
        where team_id = v_team_B_id
          and competition_id = v_competition_id;

        if v_count = 0 then
            insert into team_statistics values (v_team_B_id, v_competition_id, 0, 0, 0, 0);
        end if;
    end;

    procedure clean_records is
    begin
        update TEAM_STATISTICS
        set PLAYED = 0,
            WON    = 0,
            DRAW   = 0,
            LOST   = 0;
    end clean_records;

    procedure calculate_team_stats(p_history_game_id history_games.game_id%type,
                                   p_A_goals number,
                                   p_B_goals number) is

        v_current_A_stats team_statistics%rowtype;
        v_current_B_stats team_statistics%rowtype;
--             match info
        v_A_team_id       history_games.A_team_id%type;
        v_B_team_id       history_games.B_team_id%type;
        v_competition_id  competitions.COMPETITION_ID%type;

    begin

        --firstly check whether there is a place to insert data in table
        check_add_record(p_history_game_id);

--         get teamA_id, team_B_id, competition_id from p_history_game_id
        select A_TEAM_ID, B_TEAM_ID, COMPETITION_ID
        into v_A_team_id, v_B_team_id, v_competition_id
        from HISTORY_GAMES
                 join PHASES P
                      on HISTORY_GAMES.PHASE_ID = P.PHASE_ID
        where GAME_ID = p_history_game_id;

--         get current statistics from A team
        select *
        into v_current_A_stats
        from team_statistics
        where team_id = v_A_team_id
          and competition_id = v_competition_id;

--         get current statistics from B team
        select *
        into v_current_B_stats
        from team_statistics
        where team_id = v_B_team_id
          and competition_id = v_competition_id;

--         decide and calculate total
        if p_A_goals > p_B_goals then

--             update A team stats
            update team_statistics
            set played = v_current_A_stats.played + 1,
                won    = v_current_A_stats.won + 1
            where team_id = v_A_team_id
              and competition_id = v_competition_id;

--             update B team stats
            update team_statistics
            set played = v_current_B_stats.played + 1,
                lost   = v_current_B_stats.lost + 1
            where team_id = v_B_team_id
              and competition_id = v_competition_id;

        elsif p_A_goals < p_B_goals then

--             update A team stats
            update team_statistics
            set played = v_current_A_stats.played + 1,
                lost   = v_current_A_stats.lost + 1
            where team_id = v_A_team_id
              and competition_id = v_competition_id;

--             update B team stats
            update team_statistics
            set played = v_current_B_stats.played + 1,
                won    = v_current_B_stats.won + 1
            where team_id = v_B_team_id
              and competition_id = v_competition_id;

        elsif p_A_goals = p_B_goals then

--             update A team stats
            update team_statistics
            set played = v_current_A_stats.played + 1,
                draw   = v_current_A_stats.draw + 1
            where team_id = v_A_team_id
              and competition_id = v_competition_id;

--             update B team stats
            update team_statistics
            set played = v_current_B_stats.played + 1,
                draw   = v_current_B_stats.draw + 1
            where team_id = v_B_team_id
              and competition_id = v_competition_id;
        end if;

    end calculate_team_stats;

    procedure
        calculate_all_team_stats is

        cursor c_history_games is
            select *
            from HISTORY_GAMES;
    begin

        clean_records;
        for game in c_history_games
            loop
                calculate_team_stats(game.GAME_ID, game.A_GOALS, game.B_GOALS);
            end loop;

    end calculate_all_team_stats;
end;
/

create package body temp is

    procedure archive_All_LN19 is
        cursor games is
            select *
            from games g
                     join PHASES P on g.PHASE_ID = P.PHASE_ID
                     join COMPETITIONS C2 on P.COMPETITION_ID = C2.COMPETITION_ID
            where P.COMPETITION_ID = 'LN19';
    begin
        for game in games
            loop
                ARCHIVES.ARCHIVE_GAME_DEL(game.GAME_ID,
                                          RANDOM_GENERATING.RANDOM_SCORE(5),
                                          RANDOM_GENERATING.RANDOM_SCORE(5));
            end loop;
    end;

    procedure clear_bets_recalc_test as
    begin
        delete
        from bets;
        delete
        from odds;
        delete
        from HISTORY_ODDS;
        delete
        from CALC_TYPE_GAME;
        delete
        from CALC_TOTAL;
    end;

    procedure generate_matches_LN19 is
        v_max_id  number;
        v_max_id2 number;
        v_A_team  teams.team_id%type;
        v_B_team  teams.team_id%type;
        v_stadium teams.stadium%type;
        cursor c_phases is
            select *
            from PHASES
            where COMPETITION_ID = 'LN19';
    begin
        for phase in c_phases
            loop
                select coalesce(max(game_id), 1)
                into v_max_id
                from GAMES;
                select coalesce(max(game_id), 1)
                into v_max_id2

                from HISTORY_GAMES;
                if v_max_id < v_max_id2 then
                    v_max_id := v_max_id2;
                end if;

                v_max_id := v_max_id + 1;

                v_A_team := RANDOM_GENERATING.GET_RANDOM_TEAM();
                v_B_team := RANDOM_GENERATING.GET_RANDOM_TEAM_NO(v_A_team);

                select STADIUM
                into v_stadium
                from TEAMS
                where TEAM_ID = v_A_team;

                INSERT INTO GAMES (GAME_ID, PHASE_ID, A_TEAM_ID, B_TEAM_ID, MATCH_DATE, STADIUM)
                VALUES (v_max_id, phase.PHASE_ID, v_A_team, v_B_team, sysdate, v_stadium);
            end loop;
    end;
-- 
end;
/