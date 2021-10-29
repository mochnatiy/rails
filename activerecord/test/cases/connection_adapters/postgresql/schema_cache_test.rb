# frozen_string_literal: true

require "cases/helper"
require 'minitest/autorun'
require 'pry-rescue/minitest'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class SchemaCacheTest < ActiveRecord::TestCase
        def test_type_map_existence_in_schema_cache
          return unless current_adapter?(:PostgreSQLAdapter)

          db_config = ActiveRecord::Base.configurations.configs_for(
            env_name: 'arunit',
            name: 'primary'
          )

          connection = ActiveRecord::Base.postgresql_connection(db_config.configuration_hash)

          assert_not connection.schema_cache.additional_type_records.empty?
          assert_not connection.schema_cache.known_coder_type_records.empty?
        end
      end
    end
  end
end