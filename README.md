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

## 1. `universal_uid`

**Purpose:** Stores the canonical business definition of each universal variable. Each row represents one universal concept that can map to multiple domain-specific UIDs across technologies and variable groups.

| Column | Type | Purpose |
| --- | --- | --- |
| `universal_uid` | `INTEGER` | Primary key for the canonical variable. This is the stable, organization-wide identifier used to connect equivalent variables across different technologies and variable groups. |
| `datatype` | `TEXT` | Defines the canonical datatype expected for the universal variable, such as decimal, text, or date. |
| `context` | `TEXT` | Business description of what the universal UID represents. Provides the shared semantic meaning of the variable. |
| `unit` | `TEXT` | Unit of measure for the variable when applicable, such as MW, USD, or %. Can be `NULL` for variables without a unit. |
| `domain_uid_list` | `TEXT[]` | Convenience list of all domain-specific UIDs associated with the universal UID, such as `{S_A_1,B_A_1,W_A_1}`. This is a denormalized management/reporting field; `domain_variable` should remain the authoritative source for the mapping. |

### Example

| universal_uid | datatype | context | unit | domain_uid_list |
| --- | --- | --- | --- | --- |
| 1 | decimal | Installed capacity | MW | `{S_A_1,B_A_1,W_A_1}` |
| 2 | decimal | Total project cost | USD | `{S_A_2,B_A_2,W_A_2}` |

## 2. `domain_variable`

**Purpose:** Stores each domain-specific representation of a universal variable. A domain variable belongs to a specific technology and variable group, such as Solar + Assumption or Battery + Assumption.

| Column | Type | Purpose |
| --- | --- | --- |
| `domain_uid` | `TEXT` | Primary key for the domain-specific variable, such as `S_A_1`, `B_A_1`, or `S_W_1`. These values are globally unique. |
| `universal_uid` | `INTEGER` | Foreign key to `universal_uid.universal_uid`. Identifies the canonical business variable that this domain UID represents. |
| `technology` | `TEXT` | Technology to which the domain variable belongs, such as Solar, Battery, or Wind. |
| `variable_group` | `TEXT` | Logical grouping of the variable within the estimation process, such as Assumption, Preestimation, or Model. |
| `name` | `TEXT` | Domain-specific name or label for the variable. This can differ from the universal context because each technology or variable group may use different terminology. |
| `value` | `TEXT` | Value associated with the domain variable. Stored as text in the current design to support multiple logical datatypes. |
| `datatype` | `TEXT` | Domain-specific datatype for the variable. This can be used to describe or validate how the stored value should be interpreted. |

### Key constraint

The following combination is unique:

```text
universal_uid + technology + variable_group
```

This ensures that a universal UID maps to only one domain UID within a given technology and variable group.

### Example

| domain_uid | universal_uid | technology | variable_group | name | value | datatype |
| --- | --- | --- | --- | --- | --- | --- |
| S_A_1 | 1 | Solar | Assumption | Solar Capacity | 250 | decimal |
| B_A_1 | 1 | Battery | Assumption | Battery Capacity | 180 | decimal |
| W_A_1 | 1 | Wind | Assumption | Wind Capacity | 400 | decimal |
| S_A_2 | 2 | Solar | Assumption | Project Cost | 300000000 | decimal |

## 3. `estimation_template`

**Purpose:** Stores the effective-dated template history for each technology and variable-group combination. A new row is created whenever the active estimation template changes.

| Column | Type | Purpose |
| --- | --- | --- |
| `template_id` | `INTEGER GENERATED ALWAYS AS IDENTITY` | Surrogate primary key for an estimation template record. Generated automatically by PostgreSQL. |
| `technology` | `TEXT` | Technology to which the template applies, such as Solar, Battery, or Wind. |
| `variable_group` | `TEXT` | Variable group to which the template applies, such as Assumption, Preestimation, or Model. |
| `template_name` | `TEXT` | Business-facing name of the template, typically following the established date-plus-letter naming convention, such as `2024-09-B`. |
| `valid_from` | `DATE` | First date on which the template is considered valid for the technology and variable group. |
| `valid_to` | `DATE` | Last date on which the template is valid. `NULL` indicates that the template is currently active. |

### Example

| template_id | technology | variable_group | template_name | valid_from | valid_to |
| --- | --- | --- | --- | --- | --- |
| 1 | Solar | Assumption | 2024-01-A | 2024-01-01 | 2024-08-31 |
| 2 | Solar | Assumption | 2024-09-B | 2024-09-01 | `NULL` |
| 3 | Solar | Model | 2024-06-C | 2024-06-01 | `NULL` |
| 4 | Battery | Assumption | 2025-02-B | 2025-02-01 | `NULL` |

## Relationships

```text
universal_uid
    |
    | 1:N via universal_uid
    v
domain_variable
    |
    | logical relationship via
    | technology + variable_group
    v
estimation_template
```

- `universal_uid` to `domain_variable` is a direct foreign-key relationship.
- `domain_variable` to `estimation_template` is a logical relationship through `technology + variable_group`.
- `estimation_template` maintains history using `valid_from` and `valid_to`.
- `universal_uid.domain_uid_list` is a convenience list and should be synchronized from the authoritative mappings stored in `domain_variable`.

## Source-of-Truth Rules

- `universal_uid` is the source of truth for canonical variable meaning, datatype, context, and unit.
- `domain_variable` is the source of truth for universal UID to domain UID mappings.
- `estimation_template` is the source of truth for template history by technology and variable group.
- `universal_uid.domain_uid_list` is a denormalized convenience field and should not be maintained independently from `domain_variable`.
