create function a_nGoals(p_game_id games.game_id%type,
                         p_team_id teams.team_id%type)
    return number is
    v_goals_a history_games.a_goals%type := 0;
    v_goals_b history_games.b_goals%type := 0;
    v_team_a  teams.team_id%type;
    v_team_b  teams.team_id%type;
    v_count   number;
begin
    select count(*)
    into v_count
    from history_games
    where game_id = p_game_id;

    if v_count = 0 then
        exceptions.RAISE_EXCEPTION(EXCEPTIONS.no_game);
    end if;

    select h.a_goals, h.b_goals, h.a_team_id, h.b_team_id
    into v_goals_a, v_goals_b, v_team_a, v_team_b
    from history_games h
    where h.game_id = p_game_id;

    if v_team_a = p_team_id then
        return v_goals_a;
    elsif v_team_b = p_team_id then
        return v_goals_b;
    else
        exceptions.RAISE_EXCEPTION(EXCEPTIONS.no_team);
        return 0;
    end if;
end;
/

create function b_nGames_Between_Teams(teamA varchar, teamB varchar, lastNYears number default 5)
    return number as
    v_final number;
    v_count number;
begin
    select count(*)
    into v_count
    from teams
    where TEAM_ID = teamA
       or TEAM_ID = teamB;
    if v_count < 2 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_team);
    end if;
    if lastNYears < 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.invalid_year);
    end if;


    select count(*)
    into v_final
    from (select game_id
          from HISTORY_GAMES
          where (A_TEAM_ID = teamA and B_TEAM_ID = teamB)
             or (A_TEAM_ID = teamB and B_TEAM_ID = teamA) and MATCH_DATE > add_months(sysdate, -lastNYears * 12));
    return v_final;
end;
/

create function b_nGames_Between_Teams(teamA varchar, teamB varchar, lastNYears number default 5)
    return number as
    v_final number;
    v_count number;
begin
    select count(*)
    into v_count
    from teams
    where TEAM_ID = teamA
       or TEAM_ID = teamB;
    if v_count < 2 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_team);
    end if;
    if lastNYears < 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.invalid_year);
    end if;


    select count(*)
    into v_final
    from (select game_id
          from HISTORY_GAMES
          where (A_TEAM_ID = teamA and B_TEAM_ID = teamB)
             or (A_TEAM_ID = teamB and B_TEAM_ID = teamA) and MATCH_DATE > add_months(sysdate, -lastNYears * 12));
    return v_final;
end;
/



create function c_game_Diff_Goals(vIdGame Number)
    return number as
    v_final number;
    v_count number;
begin
    select count(*)
    into v_count
    from HISTORY_GAMES
    where GAME_ID = vIdGame;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_game);
    end if;

    select A_GOALS - B_GOALS into v_final from HISTORY_GAMES where GAME_ID = vIdGame;
    return v_final;
end;
/

