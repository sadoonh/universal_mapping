CREATE TABLE estimation_template (
    template_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    technology      TEXT NOT NULL,
    estimation_phase  TEXT NOT NULL,
    template_name   TEXT NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,

    CONSTRAINT uq_estimation_template
        UNIQUE (
            technology,
            estimation_phase,
            template_name
        ),

    CONSTRAINT chk_estimation_template_dates
        CHECK (
            valid_to IS NULL
            OR valid_to >= valid_from
        )
);