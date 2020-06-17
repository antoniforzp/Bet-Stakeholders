create procedure e_new_Game(teamA varchar,
                            teamB varchar,
                            dataHora date,
                            vCompeticao varchar)
as
    v_stadium  games.stadium%type;
    v_id       games.game_id%type;
    v_phase_id games.phase_id%type;
    v_count    number;
begin
    select count(*)
    into v_count
    from TEAMS
    where TEAM_ID = teamA
       or TEAM_ID = teamB;
    if v_count < 2 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_team);
    end if;

    select count(*)
    into v_count
    from COMPETITIONS
    where COMPETITION_ID = vCompeticao;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_competition);
    end if;

    select coalesce(max(game_id), 0)
    into v_id
    from games;
    v_id := v_id + 1;

    select *
    into v_phase_id
    from (select phase_id
          from phases
          where START_DATE < dataHora
            and END_DATE > dataHora
            and COMPETITION_ID = vCompeticao
          order by START_DATE)
    where rownum = 1;

    select STADIUM
    into v_stadium
    from TEAMS
    where TEAM_ID = teamA;

    insert into games values (v_id, v_phase_id, teamA, teamB, dataHora, v_stadium);
end;
/

