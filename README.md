# BDII — a toy database engine

Final project for *Base de Datos II* (UCSP, 2018): a small single-user database
engine in C++ with its own command language, storing every table as a
fixed-width text file and supporting secondary indexes backed by an AVL tree.

Features: create tables (`entero`, `varchar(n)`), insert, delete, update,
select (full scan or by column), and indexes that `SELECCIONAR_EN` uses
automatically when one exists. `FOR n;` repeats the next command `n` times,
which was used for timing experiments.

## Build

```bash
make            # -> build/bdii   (g++, C++17)
```

## Run

The engine reads commands from stdin, one per line, each ending in `;`.
It writes its data files (`tables.txt`, `indexes.txt`, `<table>.txt`, index
files) into the **current directory**, so run it from an empty folder:

```bash
make demo       # runs examples/demo.sql inside build/demo-data/
```

Command language (see `examples/demo.sql`):

```sql
CREAR_TABLA alumnos (id: entero, nombre: varchar(20));
INSERTAR_EN alumnos(id: 1, nombre: Ana);
SELECCIONAR_EN alumnos *;
SELECCIONAR_EN alumnos id 2;
ACTUALIZAR_EN alumnos id 2 nombre Pedro;
ELIMINAR_EN alumnos id 1;
CREAR_INDICE_EN alumnos idx (id);
ESCANEAR_EN alumnos id 3;     -- force a table scan even if an index exists
BORRAR_TABLAS;
```

Real output of the last query in the demo (the engine also prints a lot of
debug lines, kept as they were):

```
     >> selectalumnosid3
alumnos
usando índice: idx
cargar avl
100%
1
3         Rosa
Query Time: 5e-06
Execution Time: 2.2e-05
```

## Layout

```
main.cc       REPL: reads lines, splits on ';', calls ejecutar()
gestor.h      command dispatcher (ejecutar)
tables.h      CREAR_TABLA, table metadata (tables.txt)
registers.h   INSERTAR / ELIMINAR / ACTUALIZAR / SELECCIONAR on the data files
indices.h     CREAR_INDICE_EN, index metadata (indexes.txt)
avl.h nodo.h  AVL tree used to load and query an index
utility.h     helpers (last id in a table file, padding)
```

## Known issues

- Header-only design: everything is compiled from `main.cc`.
- Deleted rows are marked in place (`1-` in the data file), not compacted.
