# UID Schema Reference

### Launch the app

Start a local server from the project directory:

```bash
cd projects/universal_mapping
python3 -m http.server 8000
```

Then open:

```text
http://localhost:8000/erd_demo.html
```

Alternatively, open [`erd_demo.html`](erd_demo.html) directly without a server.

## 1. `universal_variable`

**Purpose:** Stores the canonical business definition of each universal variable. Each row represents one universal concept that can map to multiple domain-specific UIDs across technologies and estimation phases.

| Column | Type | Purpose |
| --- | --- | --- |
| `universal_uid` | `INTEGER` | Primary key for the canonical variable. This is the stable, organization-wide identifier used to connect equivalent variables across different technologies and estimation phases. |
| `datatype` | `TEXT` | Defines the canonical datatype expected for the universal variable, such as decimal, text, or date. |
| `description` | `TEXT` | Business description of what the universal UID represents. Provides the shared semantic meaning of the variable. |
| `unit` | `TEXT` | Unit of measure for the variable when applicable, such as MW, USD, or %. Can be `NULL` for variables without a unit. |

### Example

| universal_uid | datatype | description | unit |
| --- | --- | --- | --- |
| 1 | decimal | Installed capacity | MW |
| 2 | decimal | Total project cost | USD |

## 2. `domain_variable`

**Purpose:** Stores each stable domain UID and its canonical universal-variable mapping. Template-specific names, sample values, and datatypes belong to `template_domain_variable` so historical templates remain unchanged.

| Column | Type | Purpose |
| --- | --- | --- |
| `domain_uid` | `TEXT` | Primary key for the stable domain-specific identity, such as `S_A_1`, `B_A_1`, or `S_W_1`. |
| `universal_uid` | `INTEGER` | Foreign key to `universal_variable.universal_uid`. Identifies the canonical business variable represented by this domain UID. |

### Example

| domain_uid | universal_uid |
| --- | --- |
| S_A_1 | 1 |
| B_A_1 | 1 |
| W_A_1 | 1 |
| S_A_2 | 2 |

## 3. `estimation_template`

**Purpose:** Stores the effective-dated template history for each technology and estimation-phase combination. A new row is created whenever the active estimation template changes.

| Column | Type | Purpose |
| --- | --- | --- |
| `template_id` | `INTEGER GENERATED ALWAYS AS IDENTITY` | Surrogate primary key for an estimation template record. Generated automatically by PostgreSQL. |
| `technology` | `TEXT` | Technology to which the template applies, such as Solar, Battery, or Wind. |
| `estimation_phase` | `TEXT` | Estimation phase to which the template applies, such as Assumption, Preestimation, or Model. |
| `template_name` | `TEXT` | Business-facing name of the template, typically following the established date-plus-letter naming convention, such as `2024-09-B`. |
| `valid_from` | `DATE` | First date on which the template is considered valid for the technology and estimation phase. |
| `valid_to` | `DATE` | Last date on which the template is valid. `NULL` indicates that the template is currently active. |

### Example

| template_id | technology | estimation_phase | template_name | valid_from | valid_to |
| --- | --- | --- | --- | --- | --- |
| 1 | Solar | Assumption | 2024-01-A | 2024-01-01 | 2024-08-31 |
| 2 | Solar | Assumption | 2024-09-B | 2024-09-01 | `NULL` |
| 3 | Solar | Model | 2024-06-C | 2024-06-01 | `NULL` |
| 4 | Battery | Assumption | 2025-02-B | 2025-02-01 | `NULL` |

## 4. `template_domain_variable`

**Purpose:** Connects estimation templates to their domain variables. A template can contain many domain variables, and a domain variable can appear in many template versions.

| Column | Type | Purpose |
| --- | --- | --- |
| `template_id` | `INTEGER` | Foreign key to `estimation_template.template_id` and the first part of the composite primary key. |
| `domain_uid` | `TEXT` | Foreign key to `domain_variable.domain_uid` and the second part of the composite primary key. |
| `name` | `TEXT` | Domain-specific name captured for this template version. |
| `sample_value` | `TEXT` | Optional template-specific sample value. |
| `datatype` | `TEXT` | Domain-specific datatype captured for this template version. |

The composite primary key prevents the same domain variable from being assigned to the same template more than once:

```text
template_id + domain_uid
```

### Example

| template_id | domain_uid | name | sample_value | datatype |
| --- | --- | --- | --- | --- |
| 101 | S_A_1 | Solar Capacity | 250 | NUMERIC |
| 101 | S_A_2 | Project Capacity | 30000 | NUMERIC |
| 102 | S_A_1 | Updated Solar Capacity | 300 | NUMERIC |
| 102 | S_A_3 | Solar Operation Date | `NULL` | DATE |

## 5. `domain_variable_history` view

**Purpose:** Provides one read interface containing template metadata, domain identities, version-specific attributes, canonical descriptions, and an `is_latest` flag.

```sql
SELECT *
FROM domain_variable_history
WHERE technology = 'Solar'
  AND estimation_phase = 'Assumption'
  AND is_latest;
```

Users can query complete history by removing `is_latest` or filtering by `domain_uid`.

## First-time setup for a technology

Use one transaction so a technology never appears partially configured. Repeat the template and membership steps for every estimation phase the technology supports.

1. Define the technology name, estimation phases, first template names, and validity dates.
2. Inventory each domain UID, its canonical universal UID, template-specific name, sample value, and datatype.
3. Insert any canonical concepts that do not already exist in `universal_variable`. Reuse an existing universal UID when another technology represents the same concept; do not overwrite an existing canonical definition without reviewing it.
4. Insert each stable domain UID and universal mapping into `domain_variable`. A domain UID is created once and must always retain the same universal mapping.
5. Insert the initial row in `estimation_template` for one technology and estimation phase, capturing the generated `template_id`.
6. Insert the complete initial snapshot into `template_domain_variable` using that generated ID.
7. Repeat steps 5 and 6 for the technology's other estimation phases.
8. Query `domain_variable_history` to confirm the latest template contains the expected variables and canonical mappings.
9. Commit only after every phase passes validation; otherwise roll back the transaction.

Example for the first Solar Assumption template:

```sql
BEGIN;

INSERT INTO universal_variable (
    universal_uid,
    datatype,
    description,
    unit
)
VALUES
    (1, 'NUMERIC', 'Installed capacity', 'MW'),
    (2, 'NUMERIC', 'Total project cost', 'USD')
ON CONFLICT (universal_uid) DO NOTHING;

INSERT INTO domain_variable (
    domain_uid,
    universal_uid
)
VALUES
    ('S_A_1', 1),
    ('S_A_2', 2)
ON CONFLICT (domain_uid) DO NOTHING;

WITH new_template AS (
    INSERT INTO estimation_template (
        technology,
        estimation_phase,
        template_name,
        valid_from,
        valid_to
    )
    VALUES (
        'Solar',
        'Assumption',
        '2024-01-A',
        DATE '2024-01-01',
        NULL
    )
    RETURNING template_id
)
INSERT INTO template_domain_variable (
    template_id,
    domain_uid,
    name,
    sample_value,
    datatype
)
SELECT
    new_template.template_id,
    values_to_add.domain_uid,
    values_to_add.name,
    values_to_add.sample_value,
    values_to_add.datatype
FROM new_template
CROSS JOIN (
    VALUES
        ('S_A_1', 'Solar Capacity', '250', 'NUMERIC'),
        ('S_A_2', 'Project Capacity', '30000', 'NUMERIC')
) AS values_to_add(domain_uid, name, sample_value, datatype);

SELECT *
FROM domain_variable_history
WHERE technology = 'Solar'
  AND estimation_phase = 'Assumption'
  AND is_latest;

COMMIT;
```

Before relying on `ON CONFLICT DO NOTHING`, verify that any existing `universal_uid` and `domain_uid` rows carry the intended definitions and mapping. Conflict handling prevents duplicate inserts; it does not prove that pre-existing data is correct.

## Adding a new template or technology

### New template for an existing technology and phase

Treat published templates as immutable snapshots. Create a new template, copy the preceding snapshot, modify only the new copy, and preserve the old membership rows.

1. Choose the new template name and `valid_from` date.
2. Lock and identify the latest template for the same technology and estimation phase.
3. Set the preceding template's inclusive `valid_to` to one day before the new template starts.
4. Insert the new `estimation_template` row.
5. Copy every preceding `template_domain_variable` row to the new `template_id`.
6. Update names, sample values, or datatypes only on the new template's rows.
7. Remove a domain UID from the new template by deleting only its new bridge row; keep the stable `domain_variable` row and all historical memberships.
8. Add a previously unknown domain UID by first inserting its canonical universal concept when necessary, then its stable `domain_variable` row, and finally its new bridge row.
9. Query `domain_variable_history` with `is_latest` and inspect the old template without that filter to confirm both snapshots.
10. Commit the complete change together or roll it back.

The copy-forward portion can be performed atomically:

```sql
BEGIN;

WITH previous_template AS (
    SELECT template_id
    FROM estimation_template
    WHERE technology = 'Solar'
      AND estimation_phase = 'Assumption'
    ORDER BY valid_from DESC, template_id DESC
    LIMIT 1
    FOR UPDATE
),
close_previous AS (
    UPDATE estimation_template AS et
    SET valid_to = DATE '2026-01-01' - 1
    FROM previous_template AS previous
    WHERE et.template_id = previous.template_id
    RETURNING et.template_id
),
new_template AS (
    INSERT INTO estimation_template (
        technology,
        estimation_phase,
        template_name,
        valid_from,
        valid_to
    )
    VALUES (
        'Solar',
        'Assumption',
        '2026-01-A',
        DATE '2026-01-01',
        NULL
    )
    RETURNING template_id
)
INSERT INTO template_domain_variable (
    template_id,
    domain_uid,
    name,
    sample_value,
    datatype
)
SELECT
    new_template.template_id,
    previous_values.domain_uid,
    previous_values.name,
    previous_values.sample_value,
    previous_values.datatype
FROM previous_template
JOIN template_domain_variable AS previous_values
    ON previous_values.template_id = previous_template.template_id
CROSS JOIN new_template
RETURNING template_id;

-- Apply edits only to the new template ID returned above before committing.

COMMIT;
```

Capture the returned new `template_id` in the migration or application running this transaction, then use it for the additions, edits, and removals before `COMMIT`.

### Entirely new technology

An entirely new technology follows the first-time setup process rather than copying another technology's template IDs or domain UIDs.

1. Define the new technology and every estimation phase it supports.
2. Match its concepts to existing `universal_variable` rows and insert only genuinely new canonical concepts.
3. Create new technology-specific domain UIDs in `domain_variable`, each mapped to the correct universal UID.
4. Create one initial `estimation_template` row for each supported phase.
5. Populate each new template's complete `template_domain_variable` snapshot with its names, sample values, and datatypes.
6. Query `domain_variable_history` for the new technology and verify every phase, mapping, and latest-template result.
7. Confirm that no templates belonging to another technology were closed or modified.
8. Commit all phases together, or roll back the entire technology setup.

## Relationships

```text
universal_variable
    |
    | 1:N via universal_uid
    v
domain_variable                     estimation_template
    |                                      |
    | 1:N via domain_uid                   | 1:N via template_id
    +------------------+-------------------+
                       v
            template_domain_variable
```

- `universal_variable` to `domain_variable` is a direct foreign-key relationship.
- `domain_variable` to `template_domain_variable` is a direct foreign-key relationship through `domain_uid`.
- `estimation_template` to `template_domain_variable` is a direct foreign-key relationship through `template_id`.
- Together, those bridge relationships create a many-to-many relationship between domain variables and estimation templates.
- `estimation_template` maintains history using `valid_from` and `valid_to`.

## Source-of-Truth Rules

- `universal_variable` is the source of truth for canonical variable meaning, datatype, description, and unit.
- `domain_variable` is the source of truth for universal UID to domain UID mappings.
- `estimation_template` is the source of truth for template history by technology and estimation phase.
- `template_domain_variable` is the source of truth for template membership and version-specific domain names, sample values, and datatypes.
- `domain_variable_history` is the supported read interface for latest and historical domain-variable queries.
