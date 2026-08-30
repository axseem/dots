# Lexical reference tool: implementation plan

Status: proposed. This plan assumes a separate project, Zig, SQLite, an
English-first scope, and the temporary command names `lexbuild` and `lexq`.
`lex` is not available because it is a POSIX lexical-analyser command.

## Goal

Build a durable offline lexical query system with two deep modules:

- `lexbuild`: compile versioned local lexical sources into a replaceable SQLite
  database without using the network.
- `lexq`: query that database without modifying it, emitting concise terminal
  text or versioned JSON Lines.

The source artifacts are canonical. SQLite is a generated index. Kiwix,
StarDict, audio players, plotting tools, and encyclopedic collections remain
independent tools.

## Boundaries

The project owns:

- source-specific lexical import;
- source identity and provenance;
- exact, form, normalized, and full-text lexical lookup;
- terminal and machine-readable rendering;
- database integrity checks.

It does not own:

- downloading or synchronizing source files;
- Wikipedia, Kiwix, or StarDict readers;
- audio playback, plotting, paging, or interactive fuzzy selection;
- a GUI, HTTP server, daemon, or plugin system;
- automatic alignment of senses from different sources;
- a new database engine;
- arbitrary corpus concordance or Google Ngram phrase search.

Compression, checksums, downloads, paging, and audio playback should remain
external processes. For example, `gzip -dc` can stream JSONL to `lexbuild`;
the compiler does not need a gzip implementation.

## Size budget

- Milestone 2 MVP: at most 2,000 lines of maintained production Zig.
- Full English core through Milestone 3: hard review at 5,000 lines of
  maintained non-test Zig, including `build.zig`.
- Tests and fixtures are not capped; a line target must not discourage tests.
  Keep test logic data-driven and preferably below the production line count.
- SQLite, Zig's standard library, generated files, and source data are external
  dependencies and are not counted as project code.

This is a design constraint, not an invitation to compress readable code. If a
feature crosses the budget, first remove scope or compose an existing tool;
only then consider more code.

## Architecture

```text
curl/aria2 + checksums             Kiwix ZIM ──> Kiwix tools
          |                        StarDict  ──> sdcv
          v
versioned source artifacts
          |
          v
      lexbuild
          |
          v
  lexical.sqlite  --read-only-->  lexq  --> text
                                      `--> JSONL --> jq/fzf/scripts

Optional dotfiles command: ref TERM
  - invokes lexq, Kiwix, sdcv, or other peers independently
  - contains presentation policy only
```

Source adapters belong behind an internal `lexbuild` seam. Do not create one
public executable per source until an independently useful external adapter
actually exists. The supported interoperability seam is `lexq` output, not the
private SQLite schema.

## Domain language

- **Lexical source:** a named and versioned dictionary, semantic graph,
  frequency list, or pronunciation lexicon.
- **Lexical entry:** a source-specific language, headword, part-of-speech, and
  etymology grouping.
- **Sense:** a meaning asserted by one source.
- **Form:** an inflected, spelling, or regional variant.
- **Attestation:** a sourced example or quotation, optionally dated.
- **Relation:** a typed source-specific link such as synonym or hypernym.
- **Lookup key:** a derived normalized value used only for retrieval.
- **Article:** rendered query output, not a stored identity.

Source-qualified identities are mandatory. Wiktionary and OEWN senses remain
parallel unless an explicit reviewed mapping exists. Normalization must not
erase original case, spelling, stress, `ё`, or diacritics.

## Milestone 0: settle the project

1. Choose a non-conflicting project and command name.
2. Create a separate repository; keep only installation and orchestration in
   the dotfiles repository.
3. Choose the code licence independently from the imported data licences.
4. Record the glossary in `CONTEXT.md`.
5. Record one architectural decision: source artifacts are canonical, SQLite
   is generated, and the reader is read-only.
6. Pin Zig, bootstrap tests, formatting, a Nix development shell, and two empty
   commands.
7. Import the system SQLite C interface with `@cImport("sqlite3.h")` and link
   `libsqlite3`. Keep one small checked wrapper for ownership and result-code
   handling. Do not add a Zig ORM, vendor the SQLite amalgamation, or create a
   driver abstraction when only one driver exists.

Acceptance:

- `nix flake check` builds and tests Linux and the available local platform;
- all dependencies are pinned and can be vendored or cached;
- neither command performs network access;
- the new project has no dependency on the dotfiles repository.

## Milestone 1: feasibility spike

Build the narrowest end-to-end path before fixing the public interface.

1. Create synthetic fixtures plus a small attributed Wiktextract fixture.
2. Stream English Wiktextract JSONL into a temporary SQLite database.
3. Model only sources, entries, senses, forms, attestations, and
   pronunciations.
4. Add exact headword and form indexes.
5. Query one term and render plain text and provisional JSON Lines.
6. Run a full English import from a local compressed Kaikki artifact.
7. Measure wall time, peak RSS, source size, database size, temporary space,
   cold lookup latency, and warm lookup latency.
8. Run `PRAGMA integrity_check` and compare imported counts with the build
   report.

Acceptance:

- input is streamed and peak memory does not grow with source size;
- interruption cannot replace the last valid database;
- the build and its temporary files remain comfortably below 100 GB;
- exact lookup uses an index and is interactive on ordinary laptop hardware;
- the measurements and any discarded schema choices are documented.

Stop here and review the evidence. Change SQLite, language, schema, or scope now
if the full-data experiment exposes a material problem.

## Milestone 2: English Wiktionary MVP

### `lexbuild`

- Accept local source paths and metadata through one small manifest.
- Validate source type, version, and SHA-256 before import.
- Import English entries from the full English-edition Wiktextract stream.
- Preserve source IDs and revision metadata.
- Batch writes in bounded transactions.
- Build all indexes after bulk insertion where that reduces work.
- Emit a machine-readable build report.
- Build to a new path, check it, then permit an atomic switch.

### `lexq`

Initially support only:

```text
lexq TERM...
lexq search QUERY
lexq sources
```

Common options:

```text
--database PATH
--language en
--format text|jsonl
--source NAME
```

Rules:

- arguments or newline-delimited stdin may supply terms;
- stdout is data and stderr is diagnostics;
- non-TTY output has no colour or terminal control sequences;
- exact surface matches precede form and normalized fallback matches;
- every result identifies its source;
- no result is a normal outcome, distinct from database or usage errors;
- the database is opened read-only;
- JSON Lines carries an explicit output-schema version;
- the internal SQL schema is unsupported as an integration interface.

Acceptance scenarios:

- homographs with unrelated parts of speech: `lead`;
- case-sensitive ambiguity: `Polish` and `polish`;
- regional variants: `color` and `colour`;
- a multiword expression: `take apart`;
- incomplete source records;
- malformed source records with actionable diagnostics;
- an absent term;
- a corrupt or incompatible database;
- stable ordering for repeated queries.

The MVP is complete when it is useful with Wiktextract alone. Do not add more
sources to compensate for an unclear core model or interface.

## Milestone 3: enrich English

Add one source at a time, with a fixture and an explicit display section:

1. Open English WordNet for source-specific definitions and relations.
2. `wordfreq` for a versioned scalar frequency estimate.
3. CMUdict and Britfone for US and UK pronunciation supplements.
4. SQLite FTS5 for discovery, after exact lookup is stable.
5. Optional local Wiktionary audio paths; playback remains external.

Do not merge senses across sources. Group source sections at display time.
Frequency attaches to a documented form or lemma key, not implicitly to a
sense.

Acceptance:

- removing any optional source still leaves a valid database;
- source disagreements are visible rather than resolved silently;
- FTS is not required for exact lookup;
- `lexq --format jsonl` contains enough typed data for downstream tools to
  select definitions, relations, pronunciations, or attestations.

## Milestone 4: preservation and operation

1. Define a dated artifact layout outside the Nix store.
2. Add a plain fetch-and-verify script using existing download and checksum
   tools; do not build a download manager.
3. Keep current and previous verified database generations.
4. Generate a source, licence, attribution, and checksum manifest.
5. Document offline rebuild, restore, integrity-check, and update procedures.
6. Package the two commands with Nix.
7. Export or cache the complete runtime and build closures.
8. Add a Home Manager module only after the standalone package is usable.

Target update flow:

```text
fetch to dated directory
  -> verify hashes
  -> build new database
  -> run fixtures, samples, counts, and integrity checks
  -> switch `current` atomically
  -> retain previous generation
```

Updates should be manual and approximately annual at first. Freshness is less
important than a known-good, reproducible snapshot.

## Milestone 5: compose the larger reference collection

Keep Kiwix and StarDict independent. Add an optional `ref` command in the
dotfiles repository only after `lexq` is stable. It may invoke peer tools and
label their output, but must tolerate each peer being absent or failing.

Wikipedia remains a Kiwix collection. It is never imported into the lexical
database. The same rule applies to WikiMed, Stack Exchange, Project Gutenberg,
manuals, and RFC collections.

## Later, separately justified work

### Czech and Russian

- First import their English-edition Wiktextract entries through the existing
  adapter.
- Add MorphoDiTa and OpenCorpora only if Wiktionary forms are insufficient.
- Treat native-language editions as distinct sources, not translations of the
  English-edition senses.

### Historical usage

Google Books Ngrams is corpus data, not dictionary data. Prototype it as a
separate compiler/query pair or optional sidecar database. Compose its output
with `lexq`; do not force multi-gigabyte history into every lexical build.

### Microcontroller artifact

If there is a concrete device use case, add a host-side `lexpack` compiler that
produces an immutable English subset. Test SQLite read-only on the target
against a simpler sorted or perfect-hash format before choosing either. MCU
writes and the desktop database are out of scope.

## Principal risks

| Risk | Control |
|---|---|
| Wiktextract schema drift | Source adapter, real fixtures, explicit supported versions |
| Excessive build resources | Streaming, bounded batches, post-load indexes, measured full import |
| False source unification | Source-qualified IDs; no automatic sense merge |
| Public schema lock-in | Stable JSONL output; private disposable SQL schema |
| Interface growth | Two core commands; add options only for demonstrated workflows |
| Hidden online dependency | No network code; pinned artifacts and exported Nix closures |
| Data licence mistakes | Per-source metadata and generated attribution manifest |
| Corrupt replacement | Build-new, verify, atomic switch, retain previous generation |
| Too many tiny executables | Split only at independently useful seams |

## Immediate next step

Complete Milestone 0, then implement only the Milestone 1 spike. Do not design
the final schema, updater, multilingual support, history layer, Kiwix wrapper,
or MCU export before reviewing measurements from one full English import.
