-- DDL definitions for universal_uid.
CREATE TABLE universal_uid (
    universal_uid INTEGER PRIMARY KEY,
    datatype      TEXT NOT NULL,
    context       TEXT NOT NULL,
    unit          TEXT,
    domain_uid_list   TEXT[]
);