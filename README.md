# Universal Mapping

Universal Mapping is a small schema-design repository for describing how technology-specific variables relate to shared concepts and how estimation templates are cataloged. The model is documented by an Excel workbook; the workbook currently includes illustrative records, not a complete production dataset or a database implementation.

## Repository layout

| File | Role |
| --- | --- |
| `universal_mapping_schema.xlsx` | Canonical workbook representation of the proposed schema and sample data. |
| `README.md` | Human-readable inventory of the workbook structure and evidence-supported relationships. |
| `AGENTS.md` | Concise contributor guidance. |
| `universal_uid.sql` | SQL placeholder containing only a comment for future `universal_uid` DDL. |
| `domain_variable.sql` | SQL placeholder containing only a comment for future `domain_variable` DDL. |
| `estimation_template.sql` | SQL placeholder containing only a comment for future `estimation_template` DDL. |

## Workbook convention

Each worksheet represents one table. Its first row contains column names, and subsequent rows are **sample data**. Values and patterns below describe only what is observed; they are not constraints unless stated otherwise. In particular, the text `NULL` appears as a literal workbook value and should not be assumed to be a database null until a future DDL defines that conversion.

## Tables

### `universal_uid`

A catalog that appears to assign a shared identifier to a context, datatype, unit, and set of domain-specific identifiers.

| Column | Observed characteristics |
| --- | --- |
| `universal_uid` | Integer-like values; unique in the three sample rows. Appears to identify the shared concept. |
| `datatype` | Uppercase datatype labels (`NUMERIC`, `DATE`). Likely describes values associated with the concept. |
| `context` | Human-readable concept text, such as “Installed capacity.” |
| `unit` | Unit text (`MW`, `USD`) or the literal text `NULL` in the sample. |
| `domain_uid_list` | Text formatted as a brace-delimited list of `domain_uid` values. The workbook does not establish whether an eventual database should store this as an array, text, or a normalized relationship. |

The lists for universal IDs 1 and 2 include the corresponding sampled `domain_variable.domain_uid` values. Some listed IDs have no sample row, so the workbook is intentionally or potentially incomplete. This list behaves like a reverse mapping in the sample, but no uniqueness or referential-integrity constraint is established.

### `domain_variable`

Sample technology-specific variables and their apparent mapping to shared concepts.

| Column | Observed characteristics |
| --- | --- |
| `domain_uid` | Text identifier; unique in the six sample rows. Values use underscore-delimited codes, but the code structure is not defined by the workbook. |
| `universal_uid` | Integer-like value that appears to reference `universal_uid.universal_uid`. |
| `technology` | Category text; sampled values are `Solar`, `Battery`, and `Wind`. |
| `variable_group` | Category text; sampled values are `Assumption`, `Preestimation`, and `Model`. |
| `name` | Human-readable variable name. |
| `value` | Numeric in every sample row; other value types may be possible because a separate datatype column exists. |
| `datatype` | Uppercase datatype label; `NUMERIC` in every sample row. |

Rows referencing universal IDs 1 and 2 have matching sampled catalog rows and datatype labels. References to 7 and 12 do not have matching `universal_uid` sample rows, so referential completeness cannot be inferred. The workbook shows no direct link from this table to `estimation_template`; `technology` and `variable_group` are merely shared dimensions visible in both.

### `estimation_template`

A catalog of named templates by technology and variable group, with apparent effective-date ranges.

| Column | Observed characteristics |
| --- | --- |
| `template_id` | Integer-like values; unique in the six sample rows. Appears to identify a template record. |
| `technology` | Category text; sampled values are `Solar` and `Battery`. |
| `variable_group` | Category text; sampled values are `Assumption`, `Preestimation`, and `Model`. |
| `template_name` | Text names following a date-like pattern in the samples; the workbook does not define that pattern as a requirement. |
| `valid_from` | ISO-formatted date text (`YYYY-MM-DD`) in all sample rows. |
| `valid_to` | ISO-formatted date text or the literal text `NULL`, apparently indicating an open-ended range; that interpretation is inferred, not defined. |

For the sampled `Assumption` rows within a technology, adjacent date ranges do not overlap. The small sample does not establish a general non-overlap, ordering, or uniqueness rule.

## Maintenance and use

- Treat workbook rows as examples when designing imports, DDL, validation, or tests; do not promote sample categories, identifier patterns, or values to constraints without an explicit decision.
- When adding or renaming a worksheet or column, update this README in the same change.
- Keep the workbook and its three root SQL files aligned as DDL is introduced. Record database types, primary keys, foreign keys, null handling, list normalization, and date conversion explicitly in both the relevant SQL and this documentation.
- Before using the workbook for ingestion, decide how literal `NULL` values and `domain_uid_list` are converted and validate unresolved cross-table identifiers.
- Review all worksheets—not only visible sample rows—when checking future schema changes.
