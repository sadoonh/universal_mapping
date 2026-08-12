-- DDL definitions for domain_variable.
CREATE TABLE domain_variable (
    domain_uid      TEXT PRIMARY KEY,
    universal_uid   INTEGER NOT NULL,
    technology      TEXT NOT NULL,
    estimation_phase  TEXT NOT NULL,
    name            TEXT NOT NULL,
    value           TEXT,
    datatype        TEXT,

    CONSTRAINT fk_domain_variable_universal_uid
        FOREIGN KEY (universal_uid)
        REFERENCES universal_variable (universal_uid),

    CONSTRAINT uq_domain_variable_mapping
        UNIQUE (
            universal_uid,
            technology,
            estimation_phase
        )
);