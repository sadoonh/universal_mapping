# Universal Mapping

Universal Mapping describes how technology-specific variables map to shared concepts and how estimation templates are cataloged. The Excel workbook contains the proposed tables and representative records. The standalone ERD viewer renders those workbook tables using the corresponding SQL DDL as the authority for names, columns, data types, keys, nullability, uniqueness, checks, identity generation, and relationships.

## Repository layout

| File | Role |
| --- | --- |
| `universal_mapping_schema.xlsx` | Canonical workbook representation and representative sample rows. |
| `erd_demo.html` | Standalone interactive viewer of the workbook tables, modeled with the supplied SQL DDL definitions. |
| `universal_uid.sql` | Repository placeholder reserved for `universal_uid` DDL. |
| `domain_variable.sql` | Repository placeholder reserved for `domain_variable` DDL. |
| `estimation_template.sql` | Repository placeholder reserved for `estimation_template` DDL. |
| `AGENTS.md` | Concise contributor guidance. |

The repository SQL files remain placeholders. For this prototype, the viewer was reconciled against the separately supplied corresponding DDL inputs; those inputs define the structure summarized below.

## Schema

Each worksheet represents one table. Its first row contains column names and subsequent rows are illustrative data, not a complete production dataset.

### `universal_uid`

| Column | DDL definition |
| --- | --- |
| `universal_uid` | `INTEGER PRIMARY KEY` |
| `datatype` | `TEXT NOT NULL` |
| `context` | `TEXT NOT NULL` |
| `unit` | nullable `TEXT` |
| `domain_uid_list` | nullable `TEXT[]` |

The workbook includes three shared concepts. Its brace-delimited `domain_uid_list` values are displayed exactly as supplied and map coherently to the DDL array column; the viewer does not treat this convenience list as a declared foreign key.

### `domain_variable`

| Column | DDL definition |
| --- | --- |
| `domain_uid` | `TEXT PRIMARY KEY` |
| `universal_uid` | `INTEGER NOT NULL`, foreign key to `universal_uid.universal_uid` |
| `technology` | `TEXT NOT NULL` |
| `variable_group` | `TEXT NOT NULL` |
| `name` | `TEXT NOT NULL` |
| `value` | nullable `TEXT` |
| `datatype` | nullable `TEXT` |

The DDL also declares `UNIQUE (universal_uid, technology, variable_group)`. The workbook has six representative variables. Two refer to universal IDs `7` and `12`, whose parent records are not included in the workbook sample; the viewer preserves those values but does not imply that the sample alone is insertable under the foreign key.

### `estimation_template`

| Column | DDL definition |
| --- | --- |
| `template_id` | `INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY` |
| `technology` | `TEXT NOT NULL` |
| `variable_group` | `TEXT NOT NULL` |
| `template_name` | `TEXT NOT NULL` |
| `valid_from` | `DATE NOT NULL` |
| `valid_to` | nullable `DATE` |

The DDL declares `UNIQUE (technology, variable_group, template_name)` and checks that `valid_to IS NULL OR valid_to >= valid_from`. No DDL relationship connects this table to `domain_variable`; matching technology and group values are dimensions, not foreign keys.

## Interactive ERD viewer

Open [`erd_demo.html`](erd_demo.html) directly in a modern browser; it has no server or external dependencies. It includes:

- all three DDL-backed tables, every SQL field, and the declared field-level relationship;
- primary-key, foreign-key, not-null, identity, composite-unique, and check annotations;
- faithful representative rows from every workbook worksheet;
- draggable cards with live connectors and persisted layout;
- zoom, fit, reset, auto-layout, filtering, relationship visibility, and persisted theme controls;
- keyboard, pointer, touch, responsive, and accessible row-inspection behavior.

The workbook uses the literal text `NULL` in nullable sample cells. The viewer deliberately displays that text unchanged rather than silently converting it to a database null. Likewise, sample identity values are shown as workbook evidence, not as executable insert statements.

## Maintenance

- Treat `universal_mapping_schema.xlsx` as the schema/sample inventory and keep this documentation, the viewer, and root SQL scripts aligned when repository DDL is introduced.
- Use DDL—not sample patterns—as the authority for database constraints and relationships.
- Review every worksheet and all populated rows and columns when checking future schema changes.
- Before importing workbook data, define literal `NULL` conversion and ensure all referenced universal IDs exist.
