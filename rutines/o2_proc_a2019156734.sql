create procedure o2_proc_a2019156734(p_A_team_id history_comparison.A_team_id%type,
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

    select count(*)
    into v_count
    from teams
    where TEAM_ID = p_A_team_id
       or TEAM_ID = p_B_team_id;
    if v_count < 2 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_team);
    end if;

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

end;
/

