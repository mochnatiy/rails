# frozen_string_literal: true

require "cases/helper"
require 'debug'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class SchemaCacheTest < ActiveRecord::TestCase
        if current_adapter?(:PostgreSQLAdapter)
          def setup
            puts "TEST SETUP\r\n"
            @connection = ActiveRecord::Base.connection
            puts "TEST SETUP END\r\n"
            # binding.break
          end

          def test_type_map_existence_in_schema_cache
            assert_not(@connection.schema_cache.additional_type_records.empty?)
            assert_not(@connection.schema_cache.known_coder_type_records.empty?)
          end

          def test_type_map_queries_when_initialize_connection
            SQLCounter.clear_log
            db_config = ActiveRecord::Base.configurations.configs_for(
              env_name: "arunit",
              name: "primary"
            )

            assert_sql(/SELECT t.oid, t.typname/) do
              ActiveRecord::Base.postgresql_connection(db_config.configuration_hash)
            end
          end

          def test_type_map_queries_when_initialize_connection_with_schema_cache_dump
            puts "TEST RUN\r\n"
            # db_config = ActiveRecord::Base.configurations.configs_for(
            #   env_name: "arunit",
            #   name: "primary"
            # )

            # DONE: Investigate how to properly set up adapter here and use the real connection pool
            # connection = ActiveRecord::Base.postgresql_connection(db_config.configuration_hash)

            # binding.break
            tempfile = Tempfile.new(["schema_cache-", ".yml"])

            original_config = ActiveRecord::Base.connection_db_config
            new_config = original_config.configuration_hash.merge(schema_cache_path: tempfile.path)

            # ActiveRecord::Base.establish_connection(new_config)

            # assert_empty ActiveRecord::Base.connection.schema_cache.instance_variable_get(:@known_coder_type_records)
            # assert_empty ActiveRecord::Base.connection.schema_cache.instance_variable_get(:@additional_type_records)

            cache = @connection.schema_cache
            # cache = PostgreSQL::SchemaCache.new(ActiveRecord::Base.connection)
            cache.dump_to(tempfile.path)
            ActiveRecord::Base.connection.schema_cache = cache

            assert(File.exist?(tempfile))

            ActiveRecord.lazily_load_schema_cache = true

            # assert_equal(true, ActiveRecord.lazily_load_schema_cache)

            # DONE: We still have queries in the log, we may not clear it or queries run before loading schema cache
            # DONE: The log seems correct, the problem is that we do queries before we load schema cache
            # NEXT: The connection system is async, probably we don't setup test correctly so it uses NullPool
            # but not the ConnectionPool while it exists with schema cache already loaded.

            puts "TEST RUN ESTABLISH CONNECTION\r\n"
            assert_no_sql("SELECT t.oid, t.typname") do
              new_connection = ActiveRecord::Base.establish_connection(new_config)
            end
            # binding.break
            puts "TEST RUN ESTABLISH CONNECTION DONE\r\n"

            assert_not_empty ActiveRecord::Base.connection.schema_cache.instance_variable_get(:@known_coder_type_records)
            assert_not_empty ActiveRecord::Base.connection.schema_cache.instance_variable_get(:@additional_type_records)

            # DONE: We don't load schema cache here from the dump, it happens when we initialize a connection pool
            # assert_no_sql("SELECT t.oid, t.typname") do
            #   new_connection = ActiveRecord::Base.postgresql_connection(
            #     db_config.configuration_hash.merge(schema_cache_path: tempfile.path)
            #   )
            # end

            # puts new_connection.schema_cache.known_coder_type_records.inspect
          end

          def test_type_map_queries_with_custom_types
            cache = SchemaCache.new(@connection)
            tempfile = Tempfile.new(["schema_cache-", ".yml"])

            assert_no_sql("SELECT t.oid, t.typname") do
              cache.dump_to(tempfile.path)
            end

            cache = SchemaCache.load_from(tempfile.path)
            cache.connection = @connection

            assert_sql(/SELECT t.oid, t.typname, t.typelem/) do
              @connection.execute("CREATE TYPE account_status AS ENUM ('new', 'open', 'closed');")
              @connection.execute("ALTER TABLE accounts ADD status account_status NOT NULL DEFAULT 'new';")
              cache.dump_to(tempfile.path)
            end
          ensure
            @connection.execute("DELETE FROM accounts; ALTER TABLE accounts DROP COLUMN status;DROP TYPE IF EXISTS account_status;")
          end
        end
      end
    end
  end
end
