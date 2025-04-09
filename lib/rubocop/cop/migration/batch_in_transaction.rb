# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Disable transaction in batch processing.
      #
      # To avoid locking the table.
      #
      # @safety
      #   There are some cases where transaction is really needed.
      #
      # @example
      #   # bad
      #   class AddSomeColumnToUsersThenBackfillSomeColumn < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :some_column, :text
      #       User.update_all(some_column: 'some value')
      #     end
      #   end
      #
      #   # good
      #   class AddSomeColumnToUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :some_column, :text
      #     end
      #   end
      #
      #   class BackfillSomeColumnToUsers < ActiveRecord::Migration[7.0]
      #     disable_ddl_transaction!
      #
      #     def up
      #       User.unscoped.in_batches do |relation|
      #         relation.update_all(some_column: 'some value')
      #         sleep(0.01)
      #       end
      #     end
      #   end
      class BatchInTransaction < RuboCop::Cop::Base
        extend AutoCorrector

        include ::RuboCop::Migration::CopConcerns::BatchProcessing
        include ::RuboCop::Migration::CopConcerns::DisableDdlTransaction

        MSG = 'Disable transaction in batch processing.'

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
        alias on_csend on_send

        private

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          insert_disable_ddl_transaction(corrector, node)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def wrong?(node)
          batch_processing?(node) &&
            !within_disable_ddl_transaction?(node)
        end
      end
    end
  end
end
