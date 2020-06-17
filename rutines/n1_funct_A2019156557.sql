create function N1_FUNCT_A2019156557(p_client_id clients.client_id%type,
                                     p_charge clients.balance%type)
    return number as
    v_count   number;
    v_balance clients.balance%type;
begin

    --     check if client exists in database
    select count(*) into v_count from clients where client_id = p_client_id;
    if v_count = 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.no_bettor);
    end if;

--     check if charge is correct
    if p_charge <= 0 then
        EXCEPTIONS.RAISE_EXCEPTION(EXCEPTIONS.invalid_charge);
    end if;

    update CLIENTS
    set balance = balance + p_charge
    where CLIENT_ID = p_client_id;

    select BALANCE
    into v_balance
    from CLIENTS
    where client_id = p_client_id;

    return v_balance;
end;
/

