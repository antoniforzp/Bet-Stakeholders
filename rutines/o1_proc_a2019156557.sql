create procedure O1_PROC_A2019156557(p_A_team_id history_comparison.A_team_id%type,
                                     p_B_team_id history_comparison.B_team_id%type) as

    v_history_comparison history_comparison%rowtype;
    v_id                 number := 0;
    v_count              number := 0;
    v_A_win_prob         float  := 0;
    v_draw_prob          float  := 0;
    v_B_win_prob         float  := 0;

begin

    --     check if those teams exists in database
    select count(*)
    into v_count
    from TEAMS
    where TEAM_ID = p_A_team_id
       or TEAM_ID = p_B_team_id;

    if v_count != 2 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_team);
    end if;

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
end;
/

