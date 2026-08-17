-- DDL definitions for universal_variable.
CREATE TABLE universal_variable (
    universal_uid INTEGER PRIMARY KEY,
    datatype      TEXT NOT NULL,
    description   TEXT NOT NULL,
    unit          TEXT
);