-- Stable domain identities and their canonical universal mappings.
CREATE TABLE domain_variable (
    domain_uid     TEXT PRIMARY KEY,
    universal_uid  INTEGER NOT NULL,

    CONSTRAINT fk_domain_variable_universal_uid
        FOREIGN KEY (universal_uid)
        REFERENCES universal_variable (universal_uid)
);