# toy-dbms-cpp

[![CI](https://github.com/Wil12Fred/toy-dbms-cpp/actions/workflows/ci.yml/badge.svg)](https://github.com/Wil12Fred/toy-dbms-cpp/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

BDII, a toy single-user database engine in C++ with its own command language:
every table is a fixed-width text file, and secondary indexes are AVL trees
persisted to disk and picked automatically by `SELECCIONAR_EN`.

## Features

- `CREAR_TABLA` with `entero` (10 chars) and `varchar(n)` columns; schema kept in `tables.txt`.
- `INSERTAR_EN` with a primary-key check on the first column (a duplicate id is rejected).
  Values can also be generators: `increm`, `aleato(a,b)`, `basico`.
- `SELECCIONAR_EN <t> *` (full scan) and `SELECCIONAR_EN <t> <col> <value>`.
- `ACTUALIZAR_EN <t> <col> <value> <col2> <new>` and `ELIMINAR_EN <t> <col> <value>`
  (rows are tombstoned in place).
- `CREAR_INDICE_EN <t> <name> (<col>)` on an integer column: an AVL tree, split in
  buckets of one million keys, saved as `<name><bucket>.ind` / `.txt`. Select, update
  and delete use it when present; `ESCANEAR_EN` forces a table scan for comparison.
- `FOR n;` repeats the next command `n` times (used for timing experiments);
  every command prints its execution time.

## Requirements

- A C++17 compiler and `make`.
  - Debian/Ubuntu: `sudo apt install build-essential`
  - Arch: `sudo pacman -S base-devel`

## Build

```bash
make            # -> build/bdii
```

## Run

The engine reads commands from stdin, one per line, each ending in `;`. It writes
its data files (`tables.txt`, `indexes.txt`, `<table>.txt`, index files) into the
**current directory**, so run it from an empty folder:

```bash
make demo       # runs examples/demo.sql inside build/demo-data/
```

`examples/demo.sql`:

```sql
CREAR_TABLA alumnos (id: entero, nombre: varchar(20));
INSERTAR_EN alumnos(id: 1, nombre: Ana);
INSERTAR_EN alumnos(id: 2, nombre: Luis);
INSERTAR_EN alumnos(id: 3, nombre: Rosa);
SELECCIONAR_EN alumnos *;
SELECCIONAR_EN alumnos id 2;
ACTUALIZAR_EN alumnos id 2 nombre Pedro;
ELIMINAR_EN alumnos id 1;
SELECCIONAR_EN alumnos *;
CREAR_INDICE_EN alumnos idx (id);
SELECCIONAR_EN alumnos id 3;
```

Real output of the last query (the engine also prints its original debug lines):

```
     >> selectalumnosid3
alumnos
usando índice: idx
cargar avl
100%
1
3         Rosa
Query Time: 4e-06
Execution Time: 2e-05
```

Other commands: `ESCANEAR_EN alumnos id 3;` (scan even if an index exists),
`BORRAR_TABLAS;` (empties `tables.txt` and `indexes.txt`).

## Tests

```bash
make test
```

`tests/run.sh` runs each `tests/cases/<command>.sql` in a fresh temporary directory
and compares, against `tests/cases/<command>.expected`, the program's stdout (timing
lines removed), its exit status and every data file it wrote. One case per command:

| case | covers |
|---|---|
| `create` | schema line in `tables.txt` and header of each table file, 2- and 4-column tables |
| `insert` | rows written, max-id trailer, duplicate primary key rejected |
| `select` | full scan; select by first row, last row, a varchar column, a missing key, and the 4th column of a 4-column table |
| `update` | longer and shorter new values (no leftover characters) |
| `delete` | tombstone by the first column and by the 4th column |
| `index`  | index build, indexed select vs scan, index kept correct after insert, update and delete through the index |

`UPDATE=1 tests/run.sh` rewrites the expected files; review the diff before committing it.
CI also builds with `-Wall` and runs the demo.

## Project layout

```
main.cc       REPL: reads lines, splits on ';', calls ejecutar()
gestor.h      command dispatcher (ejecutar)
tables.h      CREAR_TABLA, table metadata (tables.txt)
registers.h   INSERTAR / ELIMINAR / ACTUALIZAR / SELECCIONAR on the data files
indices.h     CREAR_INDICE_EN, index metadata (indexes.txt)
avl.h nodo.h  AVL tree used to load and query an index
utility.h     helpers (last id in a table file, padding)
examples/     demo.sql
tests/        run.sh + cases/<command>.sql / .expected
```

## Known limitations

- Header-only design: everything is compiled from `main.cc`; lots of debug output.
- Deleted rows are tombstoned by writing `-` over the **second character** of the row,
  not compacted. For an id of two or more digits this overwrites a digit (`10` becomes
  `1-`), so a deleted row cannot be recovered from the file.
- Fixed-width fields are not enforced: a value longer than its column overflows into the next one.
- Indexes only on `entero` columns; after an insert into an indexed table the index is
  rebuilt from scratch (the original incremental path produced corrupt offsets).
- No error messages: an invalid command is silently ignored.

Bugs fixed while adding the tests: select by column skipped the first row of a
2-column table and never matched columns after the third; delete never matched columns
after the third; update through an index crashed with a double `fclose`; a shorter new
value left one stale character (`Ana` → `Bo` gave `Boa`); insert into an indexed table
corrupted the index.

## Background

Final project for a database systems course at a university, 2018.

## License

MIT — see [LICENSE](LICENSE).
