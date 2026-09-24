defmodule LokaR1Server.Store do
  @moduledoc """
  Raw SQLite through `Exqlite.Sqlite3`: the schema, one-statement helpers and the
  reads that rebuild a host. Values are stored as their canonical JSON text
  (`LokaR1.Codec`), so a read gives back the exact term that was written.

  A statement that SQLite refuses raises `LokaR1Server.Store.Error`; the host
  treats that as a failed write and rolls back.
  """
  alias Exqlite.Sqlite3
  alias LokaR1.Codec

  defmodule Error do
    defexception [:sql, :reason]
    @impl true
    def message(%{sql: sql, reason: reason}), do: "sqlite: #{inspect(reason)} in #{sql}"
  end

  @schema """
  CREATE TABLE IF NOT EXISTS instances (
    id TEXT PRIMARY KEY,
    world TEXT NOT NULL,
    durable TEXT NOT NULL,
    pending TEXT
  ) STRICT;
  CREATE TABLE IF NOT EXISTS receipts (
    instance TEXT NOT NULL,
    id TEXT NOT NULL,
    intent TEXT NOT NULL,
    result TEXT NOT NULL,
    PRIMARY KEY (instance, id)
  ) STRICT;
  CREATE TABLE IF NOT EXISTS ballast (bytes BLOB NOT NULL) STRICT;
  """

  @doc "Opens (creating if needed) the database file in WAL mode with `synchronous=FULL`."
  @spec open(Path.t()) :: Sqlite3.db()
  def open(path) do
    {:ok, conn} = Sqlite3.open(path)
    exec!(conn, "PRAGMA journal_mode=WAL")
    exec!(conn, "PRAGMA synchronous=FULL")
    :ok = Sqlite3.execute(conn, @schema)
    conn
  end

  @spec close(Sqlite3.db()) :: :ok
  def close(conn), do: :ok = Sqlite3.close(conn)

  @doc "Runs one statement with positional arguments and returns all rows."
  @spec exec!(Sqlite3.db(), String.t(), list()) :: [list()]
  def exec!(conn, sql, args \\ []) do
    with {:ok, stmt} <- Sqlite3.prepare(conn, sql),
         :ok <- Sqlite3.bind(stmt, args),
         {:ok, rows} <- Sqlite3.fetch_all(conn, stmt),
         :ok <- Sqlite3.release(conn, stmt) do
      rows
    else
      {:error, reason} -> raise Error, sql: sql, reason: reason
    end
  end

  @doc "Whether a transaction is open on this connection."
  @spec in_transaction?(Sqlite3.db()) :: boolean()
  def in_transaction?(conn), do: Sqlite3.transaction_status(conn) == {:ok, :transaction}

  @spec create(Sqlite3.db(), String.t(), String.t(), map()) :: :ok
  def create(conn, id, world, durable) do
    exec!(conn, "BEGIN IMMEDIATE")
    exec!(conn, "DELETE FROM receipts WHERE instance = ?1", [id])
    exec!(conn, "DELETE FROM instances WHERE id = ?1", [id])

    exec!(conn, "INSERT INTO instances (id, world, durable) VALUES (?1, ?2, ?3)", [
      id,
      world,
      Codec.encode(durable)
    ])

    exec!(conn, "COMMIT")
    :ok
  end

  @spec drop(Sqlite3.db(), String.t()) :: :ok
  def drop(conn, id) do
    exec!(conn, "BEGIN IMMEDIATE")
    exec!(conn, "DELETE FROM receipts WHERE instance = ?1", [id])
    exec!(conn, "DELETE FROM instances WHERE id = ?1", [id])
    exec!(conn, "COMMIT")
    :ok
  end

  @doc "`{world, durable, pending}` of an instance, or `nil`."
  @spec instance(Sqlite3.db(), String.t()) :: {String.t(), map(), map() | nil} | nil
  def instance(conn, id) do
    case exec!(conn, "SELECT world, durable, pending FROM instances WHERE id = ?1", [id]) do
      [[world, durable, pending]] -> {world, json(durable), pending && json(pending)}
      [] -> nil
    end
  end

  @doc "The HOST `receipts` map: `%{id => %{\"intent\" => hex, \"result\" => map}}`."
  @spec receipts(Sqlite3.db(), String.t()) :: map()
  def receipts(conn, id) do
    for [rid, intent, result] <-
          exec!(conn, "SELECT id, intent, result FROM receipts WHERE instance = ?1", [id]),
        into: %{},
        do: {rid, %{"intent" => intent, "result" => json(result)}}
  end

  @spec receipt(Sqlite3.db(), String.t(), String.t()) :: map() | nil
  def receipt(conn, id, rid) do
    case exec!(conn, "SELECT intent, result FROM receipts WHERE instance = ?1 AND id = ?2", [
           id,
           rid
         ]) do
      [[intent, result]] -> %{"intent" => intent, "result" => json(result)}
      [] -> nil
    end
  end

  @spec put_durable(Sqlite3.db(), String.t(), map()) :: :ok
  def put_durable(conn, id, durable) do
    exec!(conn, "UPDATE instances SET durable = ?2 WHERE id = ?1", [id, Codec.encode(durable)])
    :ok
  end

  @spec put_pending(Sqlite3.db(), String.t(), map() | nil) :: :ok
  def put_pending(conn, id, pending) do
    exec!(conn, "UPDATE instances SET pending = ?2 WHERE id = ?1", [
      id,
      pending && Codec.encode(pending)
    ])

    :ok
  end

  @spec put_receipt(Sqlite3.db(), String.t(), String.t(), map()) :: :ok
  def put_receipt(conn, id, rid, %{"intent" => intent, "result" => result}) do
    exec!(conn, "INSERT INTO receipts (instance, id, intent, result) VALUES (?1, ?2, ?3, ?4)", [
      id,
      rid,
      intent,
      Codec.encode(result)
    ])

    :ok
  end

  @doc """
  The `io_error` fault: pins `max_page_count` to the current file size, then
  inserts a 1 MiB blob inside the open transaction. SQLite answers SQLITE_FULL
  ("database or disk is full"), which raises `Error` like any failed write.
  """
  @spec fill!(Sqlite3.db()) :: no_return()
  def fill!(conn) do
    [[pages]] = exec!(conn, "PRAGMA page_count")
    exec!(conn, "PRAGMA max_page_count = #{pages}")
    exec!(conn, "INSERT INTO ballast (bytes) VALUES (zeroblob(1048576))")
    raise Error, sql: "ballast", reason: "the write unexpectedly succeeded"
  end

  @doc "`sqlite_version()`, `sqlite_source_id()` and `PRAGMA compile_options` of the linked engine."
  @spec identity() :: map()
  def identity do
    {:ok, conn} = Sqlite3.open(":memory:")
    [[version, source]] = exec!(conn, "SELECT sqlite_version(), sqlite_source_id()")
    options = for [o] <- exec!(conn, "PRAGMA compile_options"), do: o
    close(conn)
    %{"sqlite_version" => version, "sqlite_source_id" => source, "compile_options" => options}
  end

  defp json(text) do
    {:ok, value} = Codec.decode(text)
    value
  end
end
