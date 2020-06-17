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

