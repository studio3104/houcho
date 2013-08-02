require "sqlite3"
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'
require "houcho/config"

module Houcho
  class DB
    attr_reader :handle

    def initialize
      @handle = SQLite3::Database.new("#{Houcho::Config::APPROOT}/houcho.db")
      @handle.execute("PRAGMA foreign_keys = ON")

      @handle.execute_batch <<-SQL
        CREATE TABLE IF NOT EXISTS role (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS host (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS role_host (
          role_id INTEGER NOT NULL,
          host_id INTEGER NOT NULL,
          UNIQUE(role_id, host_id),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT,
          FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS serverspec (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS role_serverspec (
          role_id INTEGER NOT NULL,
          serverspec_id INTEGER NOT NULL,
          UNIQUE(role_id, serverspec_id),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT,
          FOREIGN KEY (serverspec_id) REFERENCES serverspec (id) ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS script (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS role_script (
          role_id INTEGER NOT NULL,
          script_id INTEGER NOT NULL,
          UNIQUE(role_id, script_id),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT,
          FOREIGN KEY (script_id) REFERENCES script (id) ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS outerrole (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE,
          data_source VARCHAR NOT NULL
        );

        CREATE TABLE IF NOT EXISTS outerrole_host (
          outerrole_id INTEGER NOT NULL,
          host_id INTEGER NOT NULL,
          UNIQUE(outerrole_id, host_id),
          FOREIGN KEY (outerrole_id) REFERENCES outerrole (id) ON DELETE RESTRICT,
          FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS role_outerrole (
          role_id INTEGER NOT NULL,
          outerrole_id INTEGER NOT NULL,
          UNIQUE(role_id, outerrole_id),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT,
          FOREIGN KEY (outerrole_id) REFERENCES outerrole (id) ON DELETE RESTRICT
        );
      SQL
    end
  end
end
