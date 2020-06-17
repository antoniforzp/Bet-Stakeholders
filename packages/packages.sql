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

create package CALC_TOTAL_CTRL is
    procedure add_game_calc_total(p_odd_id bets.ODD_ID%type,
                                  p_money_placed bets.money_placed%type);
    procedure re_game_calc_total_all;
end;
/

create package CALC_TYPE_GAME_CTRL is
    procedure add_game_type_calc_total(p_odd_id bets.ODD_ID%type,
                                       p_money_placed bets.money_placed%type);

    procedure re_game_type_calc_total_all;
end;
/

create PACKAGE EXCEPTIONS AS
    no_team number := -20501;
    no_game number := -20502;
    no_bettor number := -20503;
    no_bet number := -20504;
    no_competition number := -20505;
    invalid_bet_type number := -20506;
    invalid_bet_type_game number := -20507;
    no_money number := -20508;
    game_closed number := -20509;
    invalid_year number := -20510;
    invalid_phase_game number := -20511;
    invalid_phase_date number := -20512;
    duplicate_game number := -20513;
    duplicate_odds number := -20514;
    invalid_event_type number := -20515;
    negative_bet number := -20516;
    game_not_over number := -20517;
    prizes_paid number := -20518;

--         own
    invalid_charge number := -20519;

    procedure raise_exception(p_exception_code number);

end;
/

create PACKAGE HISTORY_COMPARISON_CTRL AS
    procedure match_comparison(p_history_game_id games.game_id%type);
    procedure re_match_comparison_all;
end HISTORY_COMPARISON_CTRL;
/

create PACKAGE ODD_CTRL AS
    procedure calculate_new_odd_A(p_game_id games.GAME_ID%type,
                                  p_A_team_id games.A_team_id%type,
                                  p_B_team_id games.B_team_id%type);
    procedure calculate_odd_A_all;
    procedure calculate_new_odd_B(p_game_id games.GAME_ID%type,
                                  p_A_team_id games.A_team_id%type,
                                  p_B_team_id games.B_team_id%type);
    procedure calculate_odd_B_all;
    procedure recalculate_odd(p_game_id odds.game_id%type);
    procedure recalculate_all_odds;
    procedure recalculate_odd2(p_game_id odds.game_id%type);
    procedure recalculate_all_odds2;
    function get_result(p_game_id games.game_id%type) return number;
end;
/

create PACKAGE PAYOUTS_CTRL AS 
    procedure calculate_payout(p_game_id games.game_id%type);
    procedure recalculate_all_payouts;
end;
/

create PACKAGE PROBABILITY_CTRL AS
    procedure re_probability_A(p_A_team_id history_comparison.A_team_id%type,
                               p_B_team_id history_comparison.B_team_id%type);
    procedure re_probability_A_all;
    procedure re_probability_B(p_A_team_id history_comparison.A_team_id%type,
                               p_B_team_id history_comparison.B_team_id%type);
    procedure re_probability_B_all;
end;
/

create package random_generating is
    procedure generate_events_game(p_game_id history_games.game_id%type);
    procedure re_generate_events_game_all;

    procedure generate_bet(p_game_id games.game_id%type, p_odd_type odds.odd_type_id%type);

    function random_score(p_top integer) return integer;
        
    function get_random_team return teams.team_id%type;
    function get_random_team_no(p_team_id teams.team_id%type) return teams.team_id%type;
end;
/

create package team_statistics_ctrl as
    procedure calculate_team_stats(p_history_game_id history_games.game_id%type,
                                   p_A_goals number,
                                   p_B_goals number);
    procedure calculate_all_team_stats;
end;
/

create package temp is
    procedure archive_All_LN19;
    procedure clear_bets_recalc_test;
    procedure generate_matches_LN19;
end;
/


