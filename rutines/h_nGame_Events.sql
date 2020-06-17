create function H_nGAME_EVENTS(vIDgame NUMBER,
                               vIDTeam teams.team_id%type,
                               vIdEventType NUMBER) return number as
    v_count number;
    v_total number := 0;
begin
    -- check if game exists in history games
    select count(*)
    into v_count
    from HISTORY_GAMES
    where GAME_ID = vIDgame;

    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_game);
        return 0;
    end if;

    -- check if team exists in that game
    select count(*)
    into v_count
    from HISTORY_GAMES
    where GAME_ID = vIDgame
      and (A_TEAM_ID = vIDTeam or B_TEAM_ID = vIDTeam);

    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_team);
        return 0;
    end if;

    -- check if team exists in that game
    select count(*)
    into v_count
    from EVENT_TYPE
    where EVENT_TYPE_ID = vIdEventType;

    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.invalid_event_type);
        return 0;
    end if;

    select count(*)
    into v_total
    from EVENTS
    where GAME_ID = vIDgame
      and TEAM_ID = vIDTeam
      and EVENT_TYPE_ID = vIdEventType;

    return v_total;
end;
/

