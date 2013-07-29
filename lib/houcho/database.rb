require 'sqlite3'

module Houcho
  class DB
    attr_reader :handle

    def initialize
      @handle = SQLite3::Database.new("#{File.dirname(__FILE__)}/../../houcho.db")
      @handle.execute("PRAGMA foreign_keys = ON")

      @handle.execute_batch <<-SQL
        CREATE TABLE IF NOT EXISTS role (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS outerrole (
          id INTEGER NOT NULL PRIMARY KEY,
          name VARCHAR NOT NULL UNIQUE,
          datasource VARCHAR NOT NULL
        );

        CREATE TABLE IF NOT EXISTS role_host (
          role_id INTEGER NOT NULL,
          name VARCHAR NOT NULL,
          UNIQUE(role_id, name),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS outerrole_host (
          outerrole_id INTEGER NOT NULL,
          name VARCHAR NOT NULL,
          UNIQUE(outerrole_id, name),
          FOREIGN KEY (outerrole_id) REFERENCES outerrole (id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS role_outerrole (
          role_id INTEGER NOT NULL,
          outerrole_id INTEGER NOT NULL,
          UNIQUE(role_id, outerrole_id),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS serverspec (
          role_id INTEGER NOT NULL,
          name VARCHAR NOT NULL,
          UNIQUE(role_id, name),
          FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE RESTRICT
        );
      SQL
    end
  end
end
