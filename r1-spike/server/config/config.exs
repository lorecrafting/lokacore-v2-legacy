import Config

# Build the NIF from the bundled SQLite amalgamation instead of downloading a
# precompiled binary, so the engine and its compile options come from source.
config :exqlite, force_build: true
