# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Use `in_batches` in batch processing.
      #
      # For more efficient batch processing.
      #
      # @safety
      #   There are some cases where we should not do that,
      #   or this type of consideration might be already done in a way that we cannot detect.
      #
      # @example
      #   # bad
      #   class BackfillSomeColumn < ActiveRecord::Migration[7.0]
      #     disable_ddl_transaction!
      #
      #     def change
      #       User.update_all(some_column: 'some value')
      #     end
      #   end
      #
      #   # good
      #   class BackfillSomeColumnToUsers < ActiveRecord::Migration[7.0]
      #     disable_ddl_transaction!
      #
      #     def up
      #       User.within_in_batches do |relation|
      #         relation.update_all(some_column: 'some value')
      #       end
      #     end
      #   end
      class BatchInBatches < RuboCop::Cop::Base
        extend AutoCorrector

        include ::RuboCop::Migration::CopConcerns::BatchProcessing

        MSG = 'Use `in_batches` in batch processing.'

        RESTRICT_ON_SEND = %i[
          delete_all
          update_all
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless wrong?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          range = node.location.selector.with(
            end_pos: node.location.expression.end_pos
          )
          corrector.replace(
            range,
            <<~TEXT.chomp
              in_batches do |relation|
                relation.#{range.source}
              end
            TEXT
          )
        end

        # @param node [RuboCop::AST::Node]
        # @return [Boolean]
        def within_in_batches?(node)
          node.each_ancestor(:block).any? do |ancestor|
            ancestor.method?(:in_batches)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def wrong?(node)
          batch_processing?(node) &&
            !within_in_batches?(node)
        end
      end
    end
  end
end
