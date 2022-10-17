# frozen_string_literal: true

module RuboCop
  module Migration
    module CopConcerns
      autoload :BatchProcessing, 'rubocop/migration/cop_concerns/batch_processing'
      autoload :ColumnTypeMethod, 'rubocop/migration/cop_concerns/column_type_method'
      autoload :DisableDdlTransaction, 'rubocop/migration/cop_concerns/disable_ddl_transaction'
    end
  end
end
