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

**Purpose:** Stores each stable domain UID and its canonical universal-variable mapping. Template-specific names, defaults, and datatypes belong to `template_domain_variable` so historical templates remain unchanged.

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
| `default_value` | `TEXT` | Optional template-specific default value. |
| `datatype` | `TEXT` | Domain-specific datatype captured for this template version. |

The composite primary key prevents the same domain variable from being assigned to the same template more than once:

```text
template_id + domain_uid
```

### Example

| template_id | domain_uid | name | default_value | datatype |
| --- | --- | --- | --- | --- |
| 101 | S_A_1 | Solar Capacity | 250 | NUMERIC |
| 101 | S_A_2 | Project Capacity | 30000 | NUMERIC |
| 102 | S_A_1 | Updated Solar Capacity | 300 | NUMERIC |
| 102 | S_A_3 | Solar Operation Date | `NULL` | DATE |

## 5. `domain_variable_history` view

**Purpose:** Provides one read interface containing template metadata, domain identities, version-specific attributes, canonical descriptions, and `is_latest`/`is_current` flags.

```sql
SELECT *
FROM domain_variable_history
WHERE technology = 'Solar'
  AND estimation_phase = 'Assumption'
  AND is_latest;
```

Users can query complete history by removing `is_latest` or filtering by `domain_uid`.

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
- `template_domain_variable` is the source of truth for template membership and version-specific domain names, defaults, and datatypes.
- `domain_variable_history` is the supported read interface for latest, current, and historical domain-variable queries.
