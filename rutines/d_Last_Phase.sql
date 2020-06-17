create function d_last_phase(vNameCompetition COMPETITIONS.NAME%type)
    return phases.phase_id%type as
    v_final phases.phase_id%type;
    v_count number;
begin
    select count(*)
    into v_count
    from COMPETITIONS c
    where c.NAME = vNameCompetition;

    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_competition);
    end if;

    select *
    into v_final
    from (select p.PHASE_ID
          from PHASES p,
               COMPETITIONS c
          where c.COMPETITION_ID = p.COMPETITION_ID
            and c.NAME = vNameCompetition
          order by p.END_DATE desc)
    where rownum = 1;

    return v_final;
end;
/

