# frozen_string_literal: true

require "cases/helper"
require 'minitest/autorun'
require 'pry-rescue/minitest'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class SchemaCacheTest < ActiveRecord::TestCase
        def setup
          @db_config = ActiveRecord::Base.configurations.configs_for(
            env_name: 'arunit',
            name: 'primary'
          )
        end

        def test_type_map_existence_in_schema_cache
          return unless current_adapter?(:PostgreSQLAdapter)

          connection = ActiveRecord::Base.postgresql_connection(@db_config.configuration_hash)

          assert_not connection.schema_cache.additional_type_records.empty?
          assert_not connection.schema_cache.known_coder_type_records.empty?
        end

        def test_yaml_dump_and_load
          return unless current_adapter?(:PostgreSQLAdapter)

          # Create an empty cache.
          @connection = ActiveRecord::Base.connection
          cache = SchemaCache.new @connection

          postgresql_connection = ActiveRecord::Base.postgresql_connection(@db_config.configuration_hash)

          assert_queries(2) do
            postgresql_connection.execute("CREATE TYPE account_status AS ENUM ('new', 'open', 'closed');")
            postgresql_connection.execute("ALTER TABLE accounts ADD status account_status NOT NULL DEFAULT 'new';")
          end

          tempfile = Tempfile.new(["schema_cache-", ".yml"])
          cache.dump_to(tempfile.path)
        ensure
          postgresql_connection.execute("DELETE FROM accounts; ALTER TABLE accounts DROP COLUMN status;DROP TYPE IF EXISTS account_status;")
        end
      end
    end
  end
end

# Understand why we have 2 queries on the assert queries and not 3 (third one being the SELECT on the oids)
# Push it to the repo
# Try to remove the dump to see if it will only use the 2 ones