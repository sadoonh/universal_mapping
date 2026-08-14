-- Bridge table connecting estimation templates to their domain variables.
CREATE TABLE template_domain_variable (
    template_id  INTEGER NOT NULL,
    domain_uid   TEXT NOT NULL,

    CONSTRAINT pk_template_domain_variable
        PRIMARY KEY (template_id, domain_uid),

    CONSTRAINT fk_template_domain_variable_template
        FOREIGN KEY (template_id)
        REFERENCES estimation_template (template_id),

    CONSTRAINT fk_template_domain_variable_domain
        FOREIGN KEY (domain_uid)
        REFERENCES domain_variable (domain_uid)
);

CREATE INDEX idx_template_domain_variable_domain_uid
    ON template_domain_variable (domain_uid);
