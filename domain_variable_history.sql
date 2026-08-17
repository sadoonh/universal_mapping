-- Read interface for complete domain-variable history and latest-template queries.
CREATE VIEW domain_variable_history AS
WITH ranked_templates AS (
    SELECT
        et.*,
        ROW_NUMBER() OVER (
            PARTITION BY technology, estimation_phase
            ORDER BY valid_from DESC, template_id DESC
        ) AS template_rank
    FROM estimation_template AS et
)
SELECT
    et.template_id,
    et.template_name,
    et.technology,
    et.estimation_phase,
    et.valid_from,
    et.valid_to,
    et.template_rank = 1 AS is_latest,
    CURRENT_DATE >= et.valid_from
        AND (et.valid_to IS NULL OR CURRENT_DATE <= et.valid_to) AS is_current,
    tdv.domain_uid,
    dv.universal_uid,
    tdv.name,
    tdv.sample_value,
    tdv.datatype,
    uv.description,
    uv.unit
FROM ranked_templates AS et
JOIN template_domain_variable AS tdv
    ON tdv.template_id = et.template_id
JOIN domain_variable AS dv
    ON dv.domain_uid = tdv.domain_uid
JOIN universal_variable AS uv
    ON uv.universal_uid = dv.universal_uid;
