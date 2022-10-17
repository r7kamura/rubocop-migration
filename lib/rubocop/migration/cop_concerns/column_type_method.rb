# frozen_string_literal: true

module RuboCop
  module Migration
    module CopConcerns
      module ColumnTypeMethod
        COLUMN_TYPE_METHOD_NAMES = ::Set.new(
          %i[
            bigint
            binary
            blob
            boolean
            date
            datetime
            decimal
            float
            integer
            numeric
            primary_key
            string
            text
            time
          ]
        ).freeze
      end
    end
  end
end
