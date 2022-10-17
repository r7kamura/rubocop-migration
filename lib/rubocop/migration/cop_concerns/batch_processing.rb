# frozen_string_literal: true

module RuboCop
  module Migration
    module CopConcerns
      module BatchProcessing
        BATCH_PROCESSING_METHOD_NAMES = ::Set.new(
          %i[
            delete_all
            update_all
          ]
        ).freeze

        class << self
          def included(klass)
            super
            klass.class_eval do
              # @!method batch_processing?(node)
              #   @param node [RuboCop::AST::SendNode]
              #   @return [Boolean]
              def_node_matcher :batch_processing?, <<~PATTERN
                (send
                  !nil?
                  BATCH_PROCESSING_METHOD_NAMES
                  ...
                )
              PATTERN
            end
          end
        end
      end
    end
  end
end
