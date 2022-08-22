# frozen_string_literal: true
require 'debug'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class SchemaCache < ActiveRecord::ConnectionAdapters::SchemaCache
        # cattr_accessor :additional_type_records, default: []
        # cattr_accessor :known_coder_type_records, default: []

        def initialize(conn)
          super(conn)

          @additional_type_records = []
          @known_coder_type_records = []
        end

        def encode_with(coder)
          super

          # coder["additional_type_records"] = self.additional_type_records
          # coder["known_coder_type_records"] = self.known_coder_type_records

          coder["additional_type_records"] = @additional_type_records
          coder["known_coder_type_records"] = @known_coder_type_records
        end

        def init_with(coder)
          @additional_type_records = coder["additional_type_records"]
          @known_coder_type_records = coder["known_coder_type_records"]

          super
        end

        def additional_type_records
          @additional_type_records
        end

        def known_coder_type_records
          @known_coder_type_records
        end

         def additional_type_records=(add_type_rec)
          @additional_type_records = add_type_rec
        end

        def known_coder_type_records=(known_code_type_rec)
          @known_coder_type_records = known_code_type_rec
        end

        def marshal_dump
          reset_version!

          [@version, @columns, {}, @primary_keys, @data_sources, @indexes, database_version, @known_coder_type_records, @additional_type_records]
        end

        def marshal_load(array)
          # binding.break
          @version, @columns, _columns_hash, @primary_keys, @data_sources, @indexes, @database_version, @known_coder_type_records, @additional_type_records = array
          @indexes ||= {}

          derive_columns_hash_and_deduplicate_values
        end
      end
    end
  end
end
