create table TEAMS
(
    TEAM_ID VARCHAR2(10) not null
        constraint PK_TEAMS_TEAM_ID
            primary key,
    NAME    VARCHAR2(50) not null,
    SPORT   VARCHAR2(30),
    STADIUM VARCHAR2(100),
    COUNTRY VARCHAR2(50)
);

create table COMPETITIONS
(
    COMPETITION_ID VARCHAR2(20) not null
        constraint PK_COMPETITIONS
            primary key,
    NAME           VARCHAR2(30),
    SPORT          VARCHAR2(30),
    COUNTRY        VARCHAR2(30),
    SEASON         VARCHAR2(30),
    START_DATE     DATE,
    END_DATE       DATE
);

create table PHASES
(
    PHASE_ID       NUMBER       not null
        constraint PK_PHASES
            primary key,
    COMPETITION_ID VARCHAR2(20) not null
        constraint FK_PHASES_COMPETITION_ID
            references COMPETITIONS,
    PHASE_NAME     VARCHAR2(30) not null,
    START_DATE     DATE         not null,
    END_DATE       DATE         not null
);

create table GAMES
(
    GAME_ID    NUMBER       not null
        constraint PK_GAMES
            primary key,
    PHASE_ID   NUMBER       not null
        constraint FK_GAMES_PHASE_ID
            references PHASES,
    A_TEAM_ID  VARCHAR2(10) not null
        constraint FK_GAMES_A_TEAM_ID
            references TEAMS,
    B_TEAM_ID  VARCHAR2(10) not null
        constraint FK_GAMES_B_TEAM_ID
            references TEAMS,
    MATCH_DATE TIMESTAMP(6) not null,
    STADIUM    VARCHAR2(50)
);

create table HISTORY_GAMES
(
    GAME_ID    NUMBER       not null
        constraint PK_HISTORY_GAMES
            primary key,
    PHASE_ID   NUMBER       not null,
    A_TEAM_ID  VARCHAR2(10) not null,
    B_TEAM_ID  VARCHAR2(10) not null,
    MATCH_DATE TIMESTAMP(6) not null,
    STADIUM    VARCHAR2(50) not null,
    A_GOALS    NUMBER       not null,
    B_GOALS    NUMBER       not null
);

create table EVENT_TYPE
(
    EVENT_TYPE_ID NUMBER not null
        constraint PK_EVENT_TYPE
            primary key,
    NAME          VARCHAR2(50)
);

create table EVENTS
(
    EVENT_ID      NUMBER       not null
        constraint PK_EVENTS
            primary key,
    EVENT_TYPE_ID NUMBER       not null
        constraint FK_EVENTS_EVENT_TYPE_ID
            references EVENT_TYPE,
    GAME_ID       NUMBER       not null
        constraint FK_EVENTS_GAME_ID
            references HISTORY_GAMES,
    TEAM_ID       VARCHAR2(10) not null
        constraint FK_EVENTS_TEAM_ID
            references TEAMS,
    EVENT_MINUTE  NUMBER       not null
);

create table TEAM_STATISTICS
(
    TEAM_ID        VARCHAR2(10) not null
        constraint FK_TEAM_STATS_TEAM_ID
            references TEAMS,
    COMPETITION_ID VARCHAR2(20) not null
        constraint FK_TEAM_STATS_COMPETITION_ID
            references COMPETITIONS,
    PLAYED         NUMBER       not null,
    WON            NUMBER       not null,
    DRAW           NUMBER       not null,
    LOST           NUMBER       not null,
    constraint PK_TEAM_STATISTICS
        primary key (TEAM_ID, COMPETITION_ID)
);

create table HISTORY_COMPARISON
(
    A_TEAM_ID      VARCHAR2(10) not null
        constraint FK_HISTORY_COMP_A_TEAM_ID
            references TEAMS,
    B_TEAM_ID      VARCHAR2(10) not null
        constraint FK_HISTORY_COMP_B_TEAM_ID
            references TEAMS,
    MATCHES_AMOUNT NUMBER       not null,
    A_WON          NUMBER       not null,
    DRAW           NUMBER       not null,
    B_WON          NUMBER       not null,
    constraint PK_HISTORY_COMPARISON
        primary key (A_TEAM_ID, B_TEAM_ID)
);

create table PROBABILITY_A
(
    PROB_A_ID    NUMBER       not null
        constraint PK_PROB_A_ID
            primary key,
    A_TEAM_ID    VARCHAR2(10) not null,
    B_TEAM_ID    VARCHAR2(10) not null,
    A_WIN_CHANCE FLOAT        not null,
    DRAW_CHANCE  FLOAT        not null,
    B_WIN_CHANCE FLOAT        not null,
    constraint FK_PROB_A_A_TEAM_ID
        foreign key (A_TEAM_ID, B_TEAM_ID) references HISTORY_COMPARISON
);

create table PROBABILITY_B
(
    A_TEAM_ID    VARCHAR2(10) not null,
    B_TEAM_ID    VARCHAR2(10) not null,
    A_WIN_CHANCE FLOAT        not null,
    DRAW_CHANCE  FLOAT        not null,
    B_WIN_CHANCE FLOAT        not null,
    PROB_A_ID    NUMBER       not null
        constraint FK_PROB_B_PROB_A_ID
            references PROBABILITY_A,
    constraint PK_PROB_B_ID
        primary key (A_TEAM_ID, B_TEAM_ID)
);

create table CALC_TOTAL
(
    GAME_ID      NUMBER not null
        constraint PK_CALC_TOTAL
            primary key,
    PLACED_TOTAL FLOAT  not null,
    MAX_PRIZE    FLOAT  not null
);

create table ODD_TYPE
(
    ODD_TYPE_ID NUMBER       not null
        constraint PK_ODD_TYPE
            primary key,
    NAME        VARCHAR2(30) not null
);

create table CALC_TYPE_GAME
(
    CALC_ID      NUMBER not null
        constraint PK_CALC_TYPE_GAME
            primary key,
    GAME_ID      NUMBER not null,
    ODD_TYPE_ID  NUMBER not null
        constraint FK_CALC_TYPE_GAME_ODD_TYPE_ID
            references ODD_TYPE,
    RESULT_PRIZE FLOAT  not null,
    PLACED       FLOAT  not null
);

create table ODDS
(
    ODD_ID      NUMBER       not null
        constraint PK_ODDS
            primary key,
    GAME_ID     NUMBER       not null
        constraint FK_ODDS_GAME_ID
            references GAMES,
    ODD_TYPE_ID NUMBER       not null
        constraint FK_ODDS_ODD_TYPE_ID
            references ODD_TYPE,
    VALUE       FLOAT        not null,
    ODD_DATE    TIMESTAMP(6) not null
);

create table HISTORY_ODDS
(
    ODD_ID      NUMBER       not null
        constraint PK_HISTORY_ODDS
            primary key,
    GAME_ID     NUMBER       not null,
    ODD_TYPE_ID NUMBER       not null,
    VALUE       FLOAT        not null,
    ODD_DATE    TIMESTAMP(6) not null
);

create table CLIENTS
(
    CLIENT_ID NUMBER       not null
        constraint PK_CLIENTS
            primary key,
    NAME      VARCHAR2(20) not null,
    SURNAME   VARCHAR2(20) not null,
    ID_NUMBER VARCHAR2(20) not null,
    PHONE_NO  VARCHAR2(20) not null,
    BALANCE   FLOAT        not null
);

create table BETS
(
    BET_ID       NUMBER not null
        constraint PK_BETS
            primary key,
    CLIENT_ID    NUMBER not null
        constraint FK_BETS_CLIENT_ID
            references CLIENTS,
    ODD_ID       NUMBER not null,
    MONEY_PLACED FLOAT  not null,
    BET_DATE     TIMESTAMP(6)
);

create table HISTORY_BETS
(
    BET_ID       NUMBER not null
        constraint HISTORY_BETS_PK
            primary key,
    CLIENT_ID    NUMBER not null,
    ODD_ID       NUMBER not null,
    MONEY_PLACED FLOAT  not null,
    BET_DATE     TIMESTAMP(6)
);

create table PAYOUTS
(
    PAYOUT_ID   NUMBER not null
        constraint PK_PAYOUTS
            primary key,
    MONEY       FLOAT  not null,
    PAYOUT_DATE DATE   not null,
    CLIENT_ID   NUMBER not null
        constraint FK_PAYOUTS_CLIENT_ID
            references CLIENTS,
    BET_ID      NUMBER not null
        constraint FK_PAYOUTS_BET_ID
            references BETS
);

create table PHYSICAL_PARAMETERS
(
    TABLE_NAME VARCHAR2(20) not null
        constraint PHYSICAL_PARAMETERS_PK
            primary key,
    TMR        NUMBER,
    ELB        NUMBER,
    NRB        NUMBER,
    NB         NUMBER,
    EIT        NUMBER,
    ENT        NUMBER
);
