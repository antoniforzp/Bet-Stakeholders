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

