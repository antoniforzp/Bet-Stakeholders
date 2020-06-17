create function n2_funct_a2019156734(p_client_id clients.client_id%type)
    return number as
    v_final1 number;
    v_final2 number;
    v_count number;
begin
    select count(*) into v_count from CLIENTS where CLIENT_ID = p_client_id;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_bettor);
    end if;

    select count(CLIENT_ID)
    into v_final1
    from BETS
    where CLIENT_ID = p_client_id;

    select count(CLIENT_ID)
    into v_final2
    from HISTORY_BETS
    where CLIENT_ID = p_client_id;

    return v_final1 + v_final2;
end;
/

