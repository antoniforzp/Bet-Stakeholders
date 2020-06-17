create procedure f_define_odds_iniciais_21a(teamA varchar, teamB varchar, dataHora date)
as
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
    v_A_win_chance probability_B.A_WIN_CHANCE%type;
    v_draw_chance  probability_B.DRAW_CHANCE%type;
    v_B_win_chance probability_B.B_WIN_CHANCE%type;
    cursor c_game is select *
                     from games
                     where (A_TEAM_ID = teamA and B_TEAM_ID = teamB)
                        or (A_TEAM_ID = teamB and B_TEAM_ID = teamA);
begin
    for record in c_game
        loop
            select count(*)
            into v_count
            from PROBABILITY_A
            where A_TEAM_ID = record.A_TEAM_ID and
                  B_TEAM_ID = record.B_TEAM_ID
               or A_TEAM_ID = record.B_TEAM_ID and
                  B_TEAM_ID = record.A_TEAM_ID;

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
                where A_TEAM_ID = record.A_TEAM_ID and
                      B_TEAM_ID = record.B_TEAM_ID
                   or A_TEAM_ID = record.B_TEAM_ID and
                      B_TEAM_ID = record.A_TEAM_ID;
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
            insert into odds values (v_id, record.game_id, 1, v_A_win, dataHora);
            v_id := v_id + 1;

--         draw odd
            insert into odds values (v_id, record.game_id, 2, v_draw, dataHora);
            v_id := v_id + 1;

--         win B odd
            insert into odds values (v_id, record.game_id, 3, v_B_win, dataHora);
        end loop;
end;
/

