# SQLite on microcontrollers

Research date: 2026-08-21. Sources are first-party SQLite and Raspberry Pi
documentation only.

## Findings

### Compilation and platform boundary

- SQLite has no published hard minimum RAM, ROM, or database size. The hard
  minimum is therefore workload/build dependent: it must provide the memory
  needed by SQLite's allocations, at least one database page when using a file,
  the application stack, and the VFS's I/O state. The smallest valid SQLite
  database is one 512-byte page; valid page sizes are powers of two from 512 to
  65536 bytes ([file format](https://www.sqlite.org/fileformat.html#pages)).
  SQLite publishes no universal minimum compiled code size either; the
  amalgamation, application, boot code, and database must share the available
  nonvolatile storage.
- A useful *soft* planning floor is not an SQLite requirement. SQLite's own
  embedded allocator documentation says its fixed heap is typically a few
  hundred kilobytes to a few dozen megabytes, depending on requirements
  ([memory allocation](https://www.sqlite.org/malloc.html)). A small, single-
  purpose, read-only query can be below that typical range, but must be measured
  with the actual schema, query, stack, and firmware. There is no defensible
  universal RAM number.
- The amalgamation is one C source file and needs only six standard C routines
  for a minimal build: `memcmp`, `memcpy`, `memmove`, `memset`, `strcmp`, and
  `strlen`. `malloc`/`realloc`/`free` are optional; a fixed application-supplied
  heap or page-cache pool is supported. Default Unix/Windows VFSes, however,
  expect OS file calls. A bare-metal target must supply a custom VFS
  ([self-contained](https://sqlite.org/draft/selfcontained.html),
  [VFS](https://www.sqlite.org/vfs.html)). POSIX is not required; correct VFS
  semantics are.
- Compile-time reductions include `SQLITE_THREADSAFE=0` (single-thread only),
  `SQLITE_DEFAULT_MEMSTATUS=0`, `SQLITE_OMIT_LOAD_EXTENSION`,
  `SQLITE_OMIT_SHARED_CACHE`, `SQLITE_OMIT_WAL`, and feature-specific omissions
  such as JSON, triggers, views, virtual tables, FTS, and floating point. The
  `SQLITE_OMIT_*` options are mostly unsupported and must be tested; SQLite
  specifically recommends testing non-standard builds. `SQLITE_OMIT_DISKIO`
  forces memory-only databases and is explicitly described as unmaintained.
  These reduce code/features, not the fundamental storage, query, page-cache,
  or durability requirements ([compile-time options](https://www.sqlite.org/compile.html)).

### RAM and page cache

- The default new-database page size is 4096 bytes, but it can be set to
  512--65536 bytes. Smaller pages reduce the minimum per-page cache allocation
  and flash update granularity, but can increase B-tree overhead and I/O. Each
  cache allocation is the page size plus an implementation/processor-dependent
  header; SQLite exposes the header size through
  `SQLITE_CONFIG_PCACHE_HDRSZ` ([memory allocation](https://www.sqlite.org/malloc.html),
  [pragma page_size](https://www.sqlite.org/pragma.html#pragma_page_size)).
- The default cache suggestion is `-2000`, meaning about 2,000 KiB regardless
  of page size, not a mandatory reservation. `cache_size` is an upper bound and
  can be reduced; query results, prepared statements, temporary storage, and
  application memory still compete for SRAM ([compile options](https://www.sqlite.org/compile.html#default_cache_size),
  [pragma cache_size](https://www.sqlite.org/pragma.html#pragma_cache_size)).
- Memory mapping is not a general RP2040 solution: SQLite's mmap benefit relies
  on an operating-system page cache and address-space mapping. Disable it for a
  custom bare-metal VFS unless that VFS deliberately implements it
  ([mmap](https://sqlite.org/mmap.html)).

### Filesystem, locking, and durability

- A writable database needs a VFS implementing file reads/writes, file size and
  deletion/truncation, locking (`NONE` through `EXCLUSIVE`), and `xSync`.
  SQLite depends on locking to exclude incompatible writers and on sync/flush
  to order durable writes. It assumes atomic file deletion, powersafe overwrite
  semantics, and that sync really reaches nonvolatile storage; violations can
  corrupt the database after reset or power loss ([atomic commit](https://www.sqlite.org/atomiccommit.html),
  [I/O methods](https://sqlite.org/c3ref/io_methods.html)).
- Rollback-journal mode needs journal storage; WAL additionally needs a `-wal`
  file and shared-memory locking. `SQLITE_OMIT_WAL` can remove WAL, but does not
  remove the need for a correct rollback-journal VFS. A single firmware task
  can simplify locking, but must not claim concurrency guarantees unless the
  VFS actually provides them.
- `PRAGMA synchronous=FULL` is the durability setting that asks the VFS to
  sync; `NORMAL`/`OFF` trade recovery guarantees for less I/O. No SQLite
  setting can repair a flash driver that cannot provide the required ordering
  and persistence ([synchronous](https://www.sqlite.org/pragma.html#pragma_synchronous)).

### RP2040 assessment

- RP2040 has dual Cortex-M0+ cores and 264 KiB embedded SRAM. It has no on-chip
  flash; it supports external QSPI flash through XIP, with a 16 KiB XIP cache
  and up to a 16 MiB XIP address window. XIP makes external flash behave like
  read-only memory for normal software reads ([RP2040 datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf),
  sections 1.2, 2.6.2, and 2.6.3; [Raspberry Pi microcontroller docs](https://www.raspberrypi.com/documentation/microcontrollers/microcontroller-chips.html#rp2040)).
- **Read-only:** technically realistic for a small, fixed database if the
  database is placed in external flash, the firmware reserves enough SRAM for
  SQLite plus the application, and a custom VFS maps page reads to flash. Use a
  deliberately small page/cache budget and simple queries. The XIP cache is
  hardware instruction/data-read caching, not SQLite's page cache, and does not
  provide SQLite file semantics.
- **Writable:** compilation is possible, but ordinary RP2040 XIP flash is a
  poor SQLite writable medium. The official SDK requires erase in 4096-byte
  sectors and programming in 256-byte pages; a zero bit cannot return to one
  without erasing the whole sector. During erase/program, XIP access must be
  stopped and concurrent flash execution can crash; the SDK requires
  synchronization and SRAM-resident safe code ([Pico SDK flash API](https://www.raspberrypi.com/documentation/pico-sdk/hardware.html#group_hardware_flash)).
  SQLite's page/journal writes therefore need sector read-modify-erase-write,
  temporary/journal space, power-fail handling, and a VFS that implements locks
  and durable sync. Firmware and database regions must also be partitioned.
- Flash endurance is not specified by the RP2040 datasheet because the flash is
  an external, board-specific part. Its vendor datasheet and any filesystem's
  wear-leveling/power-fail guarantees are required. Repeated SQLite commits can
  repeatedly erase the same sectors; without a wear-leveling storage layer,
  writable logging is not a robust design. The SDK's alignment rules alone are
  not an endurance guarantee.

## Bottom line

SQLite can be compiled for a bare-metal RP2040 and can be useful as a compact
read-only query engine. That is a compilation result, not evidence of useful
performance or safe storage. A writable database is only realistic with a
separate storage design (typically an SD/eMMC/flash translation layer or a
purpose-built append/log store), a tested custom VFS, sufficient RAM, and a
power-fail/endurance design. For ordinary RP2040 external XIP flash, use SQLite
read-only or choose a simpler embedded storage format for writes.

## Verification

- The task change is confined to this target file; the repository also contains
  a pre-existing untracked `docs/offline-lexical-reference.md`.
- Claims about minimum RAM, code size, and endurance are intentionally stated as
  non-fixed or device-dependent where the cited primary sources provide no
  numeric universal limit.
