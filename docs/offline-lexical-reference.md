# Offline lexical reference for English, Czech, and Russian

Research checked 2026-08-21. Sizes below are publisher download sizes unless
marked as estimates. They change between releases. MB/GB retain the publisher's
units.

## Conclusion

No single open dataset supplies reliable definitions, sense boundaries,
examples, semantic relations, etymology, dates, frequency, morphology, and
US/UK pronunciation in all three languages. Use separate layers:

1. **Dictionary:** start with current prebuilt Wiktionary StarDict files and
   `sdcv`. Move to English-Wiktionary data extracted by Wiktextract, restricted
   to English, Czech, and Russian, only if a unified structured query is worth
   building. Wiktextract has the broadest common schema and English glosses for
   all three languages.
2. **Semantic graph:** Open English WordNet; optionally Czech WordNet 1.9 PDT
   and RuWordNet where their non-commercial terms are acceptable.
3. **Morphology:** MorphoDiTa for Czech and OpenCorpora for Russian.
4. **Frequency:** `wordfreq` for one comparable score across all languages;
   corpus-derived lists only where provenance and domain matter.
5. **Pronunciation:** Wiktionary IPA/audio links, plus CMUdict for US English.
   Britfone is a small permissive UK supplement; BEEP is larger but restricted.
6. **Lookup:** use `sdcv` for immediate article lookup. For a richer integrated
   tool, keep normalized records in SQLite and expose a small command-line
   query. Export selected article HTML to StarDict for `sdcv` or GoldenDict-ng.

This split matters: **a corpus supplies attestations, concordances, and counts,
not lexicographic definitions**. A morphological lexicon supplies analyses and
forms, not senses. A WordNet supplies sense relations, but is not a full
learner's dictionary.

## Field coverage

Legend: **Y** systematic; **P** present but incomplete or indirect; **—** not a
purpose of the resource.

| Resource | Languages | Definitions / senses | Examples | Synonyms / antonyms | Etymology / first use | Frequency | Morphology | Pronunciation |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Wiktionary via Wiktextract | en, cs, ru | Y | P | P | P / P | — | P | P |
| Open English WordNet | en | Y | P | Y | — | — | P | P |
| Czech WordNet 1.9 PDT | cs | P | — | Y | — | — | — | — |
| RuWordNet | ru | P | — | Y | — | — | — | — |
| GCIDE | en | Y | P | P | P / P | — | P | P |
| `wordfreq` | en, cs, ru | — | — | — | — | Y | — | — |
| MorphoDiTa model | cs | — | — | — | — | — | Y | — |
| OpenCorpora dictionary | ru | — | — | — | — | — | Y | — |
| CNC SYN / RNC / OpenCorpora corpora | cs or ru | — | concordances | — | attestations only | Y | annotation | — |
| CMUdict / Britfone / BEEP | en-US / en-GB | — | — | — | — | — | — | Y |

“First known use” needs special caution. Wiktionary entries sometimes contain
“first attested” prose or dated quotations, but Wiktextract does not promise a
normalized first-use field. A dated quotation is evidence of an attestation,
not proof that no earlier use exists. Merriam-Webster explains the same
limitation for its editorial First Known Use dates, but its data is not an open
offline dataset ([Merriam-Webster notes][mw-dates]).

## Dictionary layer

### Wiktionary dumps, Wiktextract, and Kaikki

Wikimedia publishes current-page XML dumps as `.xml.bz2`. The August 2026 dumps
were about 1.62 GB for English Wiktionary, 334 MB for Russian Wiktionary, and
48 MB for Czech Wiktionary (`pages-articles.xml.bz2`)
([English index][en-dump], [Russian index][ru-dump], [Czech dump report][cs-dump]).
The XML is source material, not a ready lookup database: templates and Lua
modules must be expanded.

[Wiktextract][wiktextract] performs that expansion and emits JSON Lines. Its
documented records include senses/glosses, examples and quotations, inflected
forms, IPA and sound-file URLs, translations, etymology text/templates, and
lexical relations such as synonyms and antonyms. Coverage remains whatever
volunteers encoded; fields are not complete merely because the schema supports
them.

[Kaikki raw downloads][kaikki-raw] avoid local extraction. At retrieval time:

| Data | JSONL | gzip | Update statement |
|---|---:|---:|---|
| Full English-edition extraction, all languages | 22.9 GB | 2.6 GB | usually at least weekly |
| Czech-edition extraction, all languages | 264.3 MB | 36.6 MB | usually at least weekly |
| English entries selected from English edition | 3.0 GB | not stated on page | postprocessed download is deprecated |
| Czech entries selected from English edition | 190.8 MB | not stated on page | postprocessed download is deprecated |
| Russian entries selected from English edition | 893.3 MB | not stated on page | postprocessed download is deprecated |

The three language-selected figures come from Kaikki's [English][kaikki-en],
[Czech][kaikki-cs], and [Russian][kaikki-ru] pages. Because those convenient
postprocessed files are explicitly deprecated, a durable updater should stream
the 2.6 GB raw gzip and retain records whose `lang_code` is `en`, `cs`, or `ru`.
Do not load the whole extraction into memory.

Prefer the English edition as the common source: all glosses use one display
language and its extraction is the best documented. Add Czech- and
Russian-edition extractions only if native-language glosses are required;
edition records are not guaranteed to align sense-for-sense.

The extractor software is MIT-licensed, but the extracted content retains
Wiktionary's licenses. Wikimedia says original textual dump content is generally
CC BY-SA 4.0 and GFDL; imported items or media can differ
([dump licensing][wm-license]). Preserve source attribution, revision/source
URLs, and share-alike notices when redistributing. Audio is separate: Kaikki's
20.4 GB bulk archive is not automatically updated and each Commons file can
have its own attribution requirements.

### WordNet variants

**Open English WordNet (OEWN)** is the preferred English semantic graph. It
groups senses into synsets and records hypernymy, antonymy, meronymy, and other
relations. The 2025 release offers WNDB (9.2 MB), WN-LMF XML gzip (10.8 MB),
JSON zip (9.5 MB), and RDF gzip (16.9 MB). Releases have been annual since 2019
([downloads and history][oewn-downloads]). OEWN is derived from Princeton
WordNet and is CC BY 4.0 ([OEWN site][oewn-license]). Use WN-LMF/JSON for a
new importer; WNDB is mainly for legacy WordNet tools.

Princeton WordNet 3.0 remains widely packaged and has a permissive attribution
license ([license][pwn-license]), but it is static. Debian's `dict-wn` is a
convenient DICT rendering (10.35 MB package, 12.26 MB installed), while OEWN is
the maintained choice ([Debian package][dict-wn]). Neither is a substitute for
Wiktionary's etymologies, broad morphology, or current vocabulary.

**Czech WordNet 1.9 PDT** has 23,094 noun, verb, adjective, and partial-adverb
word senses. The downloadable 2011 snapshot is CC BY-NC-SA 3.0
([LINDAT metadata][czwn]). It is useful for synsets and semantic relations but
old, non-commercial, and much narrower than a general dictionary. Newer Czech
WordNet versions are not offered there as an equivalent open update.

**RuWordNet** reports 29,297 noun, 12,865 adjective, and 7,636 verb synsets,
111,500 unique words/expressions, and relations including antonymy,
hypernymy/hyponymy, part-whole, domains, cause, and entailment. Its project
states that XML is distributed for **non-commercial use by email request**
([project README][ruwordnet]). This is not a frictionless redistributable
download. Treat its WordNet definitions carefully: the browser visibly links
some synsets to English WordNet glosses, rather than providing a comprehensive
Russian explanatory dictionary.

### GCIDE and package dictionaries

GCIDE is useful as a tiny, entirely local English fallback. Debian's
`dict-gcide` is 14.45 MB compressed and 17.10 MB installed. It combines the
1913 Webster text, WordNet, Century Dictionary material, and volunteer edits;
Debian explicitly warns that much of the core is old ([package page][gcide]).
It can contain definitions, usage examples, pronunciation spellings, and
etymological notes, but modern coverage and labels are uneven.

FreeDict and WikDict are principally **bilingual translation dictionaries**,
not explanatory references. FreeDict currently lists English→Czech (150,004
headwords), English→Russian (62,181), Russian→English (42,600), and much smaller
Czech→English (488) data, among others ([downloads][freedict]). It distributes
TEI and ready DICT files. WikDict publishes CC BY-SA StarDict downloads derived
from Wiktionary/DBnary ([download terms][wikdict]); current archives include
`cs-en`, `ru-en`, `cs-ru`, and reverse directions. These are convenient
translation supplements, but they discard much of Wiktionary's rich article
structure.

Debian dictionary packages are operationally attractive because package
metadata records exact versions and licenses. For example, `dict-gcide` and
`dict-wn` total about 29.4 MB installed. Debian and Arch Hunspell packages are
spelling/morphology wordlists, not definition dictionaries; Arch's current
`hunspell-en_us` is 2.1 MB installed ([Arch package][hunspell]). Do not present
Hunspell/Aspell word lists as lexical references.

### Ready-to-use Wiktionary renderings

The [Wiktionary StarDict project][wikt-stardict] publishes frequently regenerated
StarDict archives that retain rendered Wiktionary articles. Its 2026-08-19
release offers English-edition English→English (785,221 entries, 98 MB),
Czech→English (48,064, 5 MB), and Russian→English (63,595, 19 MB). From the
Russian edition, Russian→Russian has 479,331 entries and is 125 MB
([download catalogue][wikt-stardict-downloads]). The listed sizes are outer
`.tar.zst` downloads, not measured extracted sizes.

This is the best low-effort `sdcv` starting point: about 122 MB downloaded for a
common English-gloss set, or about 247 MB with native Russian definitions. The
catalogue currently has no Czech-edition output, so native Czech explanatory
coverage needs the Czech Wiktionary ZIM or a custom Czech Wiktextract import.
Rendered StarDict is pleasant for humans but unsuitable for reliable field-level
queries such as “show only dated quotations” or joining frequency by sense.

The converter is GPL-3.0-or-later; the source articles retain Wikimedia content
licensing. Prefer these clearly sourced builds over miscellaneous StarDict
archives containing unlicensed commercial dictionaries.

### Kiwix Wiktionary ZIM

Kiwix provides compressed, indexed snapshots that preserve the rendered
Wiktionary site with almost no setup. Current no-picture ZIMs are 8.5 GB for the
English edition, 144 MB for Czech, and 1.7 GB for Russian
([Kiwix catalogue][kiwix-wikt]). These are *editions*, not language filters: the
8.5 GB English ZIM contains entries for many languages. The three total about
10.3 GB and provide native-language articles without writing an importer.

`kiwix-tools` supplies `kiwix-search` and `kiwix-serve`; the latter gives a local
offline web interface. ZIM is highly compressed and supports random access, but
it stores rendered pages rather than a convenient relational schema. It is best
for faithful reading, poor for composing one terminal report from dictionary,
frequency, and morphology sources.

## Morphology

### Czech: MorphoDiTa

MorphoDiTa provides morphological analysis, generation, lemmatization, and POS
tagging. The software is MPL 2.0, while current Czech models are CC BY-NC-SA
4.0 and can inherit additional source-data conditions. The current manual names
the Czech MorfFlex2+PDT-C model and documents model variants around 9.5–30.4 MB
([manual][morphodita]). This is the right layer for mapping an inflected query
to candidate lemmas before dictionary lookup, and for generating paradigms.
It does not define words or distinguish lexical senses.

### Russian: OpenCorpora

OpenCorpora provides a morphological dictionary, tagged texts, frequency
lists, and collocations under CC BY-SA 3.0. Its current download page lists a
16.18 MB `.bz2` XML morphology dictionary (14.03 MB plain-text `.bz2`), a
31.24 MB `.bz2` XML corpus, and an approximately 160 MB weekly database dump
([downloads][opencorpora]). The downloadable corpus has about 1.99 million
tokens and only partial ambiguity resolution, so it is valuable for morphology
and testing, but too small and composition-dependent to be the sole authority
for general Russian frequency.

## Frequency and corpora

### Comparable local score: `wordfreq`

`wordfreq` gives frequency estimates for English, Czech, and Russian from
several domains rather than from one corpus. Its source table documents five
source groups for Czech and Russian and seven for English. The package is
Apache 2.0 and its bundled frequency data is CC BY-SA 4.0
([README][wordfreq]). Version 3.1.1 is a 56.8 MB wheel. The maintainer states
that the frequencies are a snapshot through about 2021 and are unlikely to be
updated. Therefore store its Zipf score and version, not a false “current
corpus count.”

### Czech National Corpus

SYN version 14 contains almost 5.5 billion words; SYN2025 is a balanced,
representative 100-million-word corpus focused on 2020–2024 and is lemmatized,
morphologically tagged, and syntactically annotated
([CNC overview][cnc-overview], [SYN2025][syn2025]). These are strong sources
for frequency distributions and concordance evidence. They are accessed through
the CNC's corpus services; the cited pages do not offer the full copyrighted
SYN text as a freely redistributable offline bundle. Derived lists must retain
their corpus/version and obey CNC terms. Do not budget 5.5 billion words as a
download unless a separate licensed distribution has actually been obtained.

### Russian National Corpus

The RNC reports more than 13 billion tokens overall and provides annotated
search and frequency tools ([home][rnc]). It is excellent for checking usage,
genre, and period online, but not suitable as the proposed offline corpus. The
FAQ says full texts usually cannot be downloaded and limits published data to
non-commercial research/education; its database license prohibits transferring
or publishing the database or fragments except specified legal exceptions
([FAQ][rnc-faq], [database license][rnc-license]). Export only permitted
derived results/citations with attribution. OpenCorpora is the practical open
offline Russian corpus, despite its much smaller size.

### Historical frequency and earliest evidence

[Google Books Ngram exports][google-ngrams] provide yearly 1–5-gram counts for
English (including separate US and UK corpora) and Russian, but not Czech. The
downloadable 2020-version shards are gzip-compressed TSV and the compilation is
CC BY 3.0. The files retain `ngram`, year, match count, and volume count; total
counts permit normalization. This is useful for a historical usage curve, not a
dictionary “first used” field. Google omits n-grams below its corpus threshold,
and OCR, spelling change, corpus composition, and book metadata can all make the
earliest returned year misleading.

The export catalogue does not state aggregate byte totals. Complete 1–5-gram
mirrors are a large-data project, not a dictionary add-on. For a personal tool,
either retain yearly counts only for a fixed headword list during a one-time
streaming pass, or omit this layer. Arbitrary offline phrase curves require the
much larger 2–5-gram shards. gzip compresses the repetitive TSV well but does
not give convenient random access; convert selected records to SQLite or
Parquet and discard the shards.

For Czech, [Diakorp][diakorp] spans seven centuries but is only about 4.13
million tokens in its listed v6 and is neither representative nor balanced.
Like the larger CNC datasets, it is a hosted corpus, not a general open offline
download. For Russian, RNC's Word at a Glance reports a first mention and warns
users to check earlier corpora before treating it as comprehensive
([RNC word tool][rnc-word]). Neither source solves the offline requirement.

Therefore expose three distinct values when available: `dictionary attestation
note`, `earliest dated quotation`, and `earliest corpus hit`. Never label the
latter two simply “year coined” or “year first used.” Comprehensive editorial
dates are strongest in commercial historical dictionaries such as OED, whose
data is not available as an open offline bulk corpus.

## Pronunciation and etymology

- **Wiktionary/Wiktextract:** common cross-language source for IPA, accent
  labels, hyphenation, and Commons audio URLs. Download text metadata by
  default; audio adds about 20.4 GB and per-file license handling.
- **CMUdict:** US English ARPAbet pronunciations. CMU permits research and
  commercial use and requests acknowledgement ([repository][cmudict]). It is
  compact plain text and easy to index, but has no definitions.
- **Britfone:** about 16,000 Standard Southern British entries in IPA under MIT
  ([repository][britfone]). Useful but small.
- **BEEP:** over 250,000 British English transcriptions in a 2.7 MB gzip, but
  only for research/development and not commercial use because of inherited
  OUP/MRC restrictions ([OpenSLR record][beep]). Do not redistribute it in a
  general-purpose package.
- **Etymology:** Wiktionary is the only broad, openly downloadable option found
  for all three languages. GCIDE is an old English supplement. Commercial
  Oxford/Cambridge data cannot simply be cached: Oxford's standard API terms
  prohibit systematic download and offline storage without a separate license
  ([Oxford terms][oxford-terms]). No evidence was found that Etymonline offers
  an official bulk dataset; do not scrape it into the stack.

## Clients and formats

| Client/format | Strength | Weakness | Use here |
|---|---|---|---|
| SQLite + small CLI | Preserves structured senses, relations, provenance, forms, and numeric frequency; one indexed query | Requires an importer and renderer | Primary terminal interface |
| `sdcv` / StarDict | Tiny terminal client; exact, fuzzy, wildcard, and full-text search; easy user data directory | Article-oriented format loses typed graph/provenance unless embedded in HTML/JSON | Fast human lookup export |
| `dict` + local `dictd` | Stable RFC 2229 client/server; compressed random access with dictzip; Debian dictionaries work directly | Server/configuration overhead; flat articles | Package dictionaries and LAN sharing |
| Kiwix ZIM / `kiwix-tools` | Faithful, highly compressed Wiktionary pages; ready-made native editions | Large English edition; local web UI rather than polished terminal articles; poor structured access | Zero-build comprehensive fallback |
| GoldenDict-ng | Rich rendering, audio, morphology, and many local formats | GUI, not the terminal requirement | Optional visual companion |
| Raw JSONL | Lossless interchange and streaming updates | Poor interactive lookup; large | Update/input format only |

`sdcv` is about 183 KB installed on Debian amd64 and 156 KB on Arch. Its manual
documents `STARDICT_DATA_DIR`, interactive/non-interactive operation, fuzzy,
wildcard, and full-text queries ([Debian][sdcv-debian], [manual][sdcv-man]). A
StarDict dictionary normally has `.ifo`, `.idx`, `.dict`/`.dict.dz`, and
optional `.syn`; dictzip compresses article data while retaining random access.

`dictd` is about 296 KB installed on Debian amd64 (354 KB on Arch) and includes
`dict`, `dictd`, `dictfmt`, and `dictzip` ([Debian][dictd-debian],
[Arch][dictd-arch]). It is better when several programs or hosts should query
the same local dictionaries; otherwise `sdcv` has fewer moving parts.

[GoldenDict-ng's format documentation][goldendict-formats] lists StarDict,
DICT, MDict, DSL, XDXF, Zim, Slob, and other formats. It can read the same
StarDict export and play linked local audio. Keep it optional.

[PyGlossary][pyglossary] is useful for conventional format conversion, but a
generic conversion cannot infer a good sense model. Build SQLite directly from
Wiktextract JSONL, then render controlled StarDict articles; do not make
StarDict the canonical database.

On this Nix-based setup, the relevant package attributes exist as `sdcv`,
`wordnet`, `dictd`, `kiwix-tools`, and `goldendict-ng`. A disposable trial is:

```sh
nix shell nixpkgs#sdcv nixpkgs#wordnet nixpkgs#kiwix-tools
```

Put extracted StarDict directories under one directory and point
`STARDICT_DATA_DIR` at it. `sdcv word` then queries all enabled dictionaries;
`sdcv -u <book-name> word` selects one. The legacy `wordnet` package gives the
small `wn` terminal browser for Princeton WordNet; prefer OEWN data for a custom
integrated importer.

## Recommended implementation

### Canonical records

Store at least these tables:

- `entry(id, language, lemma, pos, etymology_number, source, source_revision)`
- `sense(id, entry_id, ordinal, gloss, raw_gloss, labels)`
- `example(sense_id, text, translation, citation, date)`
- `form(entry_id, form, tags, romanization)`
- `relation(source_sense_or_entry, type, target_text, target_id)`
- `pronunciation(entry_id, ipa, variety_tags, audio_url, local_audio_path)`
- `frequency(language, normalized_form, score, source, source_version)`
- `analysis(language, surface, lemma, tags, analyzer_version)`

Use Unicode NFC, but preserve original spelling, stress marks, `ё`, and
diacritics. Keep accent-insensitive/case-folded search keys separately. Do not
merge Wiktionary and WordNet senses by spelling alone; retain source IDs and
display parallel source sections unless a reviewed mapping exists.

Lookup order:

1. exact surface entry;
2. language-specific morphological analyses and their lemmas;
3. normalized spelling fallback;
4. show dictionary senses, then semantic relations, frequency/provenance, and
   pronunciation;
5. permit explicit source and language filters.

### Disk tiers

These are planning estimates, not measured installed totals. SQLite indexes and
rendered articles depend strongly on retained fields and compression.

| Tier | Contents | Expected disk |
|---|---|---:|
| Minimal | `sdcv` or CLI; GCIDE + WordNet/OEWN; `wordfreq`; CMUdict/Britfone; WikDict/FreeDict translations | about 0.15–0.35 GB |
| Prebuilt practical | `sdcv`; English-edition en/cs/ru StarDict files; native Russian StarDict; `wordfreq`; OEWN | about 0.3–0.6 GB after extraction and indexes |
| Recommended | Three filtered Kaikki datasets (3.0 GB + 190.8 MB + 893.3 MB source JSONL), SQLite/indexes, OEWN, `wordfreq`, Czech/Russian morphology | about 6–10 GB working set |
| Faithful web snapshot | English, Czech, and Russian Wiktionary ZIM editions plus Kiwix | about 10.3 GB |
| Reproducible updater | Recommended tier plus full raw Kaikki gzip (2.6 GB), extraction/update workspace, original downloads | about 12–20 GB temporary/working disk |
| With Wiktionary audio | Reproducible tier plus Kaikki audio archive | add at least 20.4 GB, plus extracted/index overhead |

The recommended tier can be smaller if raw JSONL is discarded after import or
larger if examples, categories, translations, and duplicate inflected-form
entries are all retained. Measure one import before fixing a storage budget.

### Update policy

- Pin every URL to a dated dump/release and record hashes.
- Refresh Kaikki monthly even though it normally updates weekly; weekly churn
  adds little value to a personal lexical reference.
- Refresh OEWN annually and OpenCorpora/MorphoDiTa when their source page
  changes.
- Treat `wordfreq` 3.1.1 as a frozen versioned dataset.
- Rebuild in a new database, run count/sample/integrity checks, then atomically
  replace the old database.
- Generate an attribution manifest from every included source and ship it with
  any redistributed database.

## Sources

[beep]: https://openslr.org/14/
[britfone]: https://github.com/JoseLlarena/Britfone
[cmudict]: https://github.com/cmusphinx/cmudict
[cnc-overview]: https://wiki.korpus.cz/doku.php/en:cnk:uvod
[cs-dump]: https://dumps.wikimedia.org/cswiktionary/latest/
[czwn]: http://hdl.handle.net/11858/00-097C-0000-0001-4880-3
[dict-wn]: https://packages.debian.org/stable/text/dict-wn
[dictd-arch]: https://archlinux.org/packages/extra/x86_64/dictd/
[dictd-debian]: https://packages.debian.org/trixie/dictd
[diakorp]: https://wiki.korpus.cz/doku.php/en:cnk:diakorp
[en-dump]: https://dumps.wikimedia.org/enwiktionary/latest/
[freedict]: https://freedict.org/downloads/
[gcide]: https://packages.debian.org/trixie/text/dict-gcide
[google-ngrams]: https://storage.googleapis.com/books/ngrams/books/datasetsv3.html
[goldendict-formats]: https://xiaoyifang.github.io/goldendict-ng/dictformats/
[hunspell]: https://archlinux.org/packages/extra/any/hunspell-en_us/
[kaikki-cs]: https://kaikki.org/dictionary/Czech/index.html
[kaikki-en]: https://kaikki.org/dictionary/English/index.html
[kaikki-raw]: https://kaikki.org/dictionary/rawdata.html
[kaikki-ru]: https://kaikki.org/dictionary/Russian/index.html
[kiwix-wikt]: https://download.kiwix.org/zim/wiktionary/
[morphodita]: https://github.com/ufal/morphodita/blob/master/MANUAL
[mw-dates]: https://www.merriam-webster.com/help/explanatory-notes/dict-dates
[oewn-downloads]: https://en-word.net/downloads
[oewn-license]: https://en-word.net/
[opencorpora]: https://opencorpora.org/?page=downloads
[oxford-terms]: https://developer.oxforddictionaries.com/api-terms-and-conditions
[pwn-license]: https://wordnet.princeton.edu/license-and-commercial-use
[pyglossary]: https://github.com/ilius/pyglossary
[rnc-faq]: https://ruscorpora.ru/en/page/faq
[rnc-license]: https://ruscorpora.ru/file/license_dataset_main_disamb_eng/
[rnc-word]: https://ruscorpora.ru/en/page/tool-word/
[rnc]: https://ruscorpora.ru/en/
[ru-dump]: https://dumps.wikimedia.org/ruwiktionary/latest/
[ruwordnet]: https://github.com/Zebradil/RuWordNet
[sdcv-debian]: https://packages.debian.org/trixie/utils/sdcv
[sdcv-man]: https://man.archlinux.org/man/sdcv.1.en
[syn2025]: https://wiki.korpus.cz/doku.php/en:cnk:syn2025
[wikdict]: https://www.wikdict.com/page/download
[wiktextract]: https://github.com/tatuylonen/wiktextract/blob/master/README.md
[wikt-stardict]: https://github.com/xxyzz/wiktionary_stardict
[wikt-stardict-downloads]: https://xxyzz.github.io/wiktionary_stardict/
[wm-license]: https://dumps.wikimedia.org/legal.html
[wordfreq]: https://github.com/rspeer/wordfreq
