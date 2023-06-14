# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
      #
      # To avoid blocking writes.
      #
      # @safety
      #   Only meaningful in PostgreSQL.
      #
      # @example
      #   # bad
      #   class AddIndexToUsersName < ActiveRecord::Migration[7.0]
      #     def change
      #       add_index :users, :name
      #     end
      #   end
      #
      #   # good
      #   class AddIndexToUsersNameConcurrently < ActiveRecord::Migration[7.0]
      #     disable_ddl_transaction!
      #
      #     def change
      #       add_index :users, :name, algorithm: :concurrently
      #     end
      #   end
      class AddIndexConcurrently < RuboCop::Cop::Base
        extend AutoCorrector

        include ::RuboCop::Migration::CopConcerns::DisableDdlTransaction
        include RangeHelp

        MSG = 'Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.'

        MESSAGE_FOR_DUPLICATED_DISABLE_DDL_TRANSACTION = 'Remove duplicated `disable_ddl_transaction!`.'

        RESTRICT_ON_SEND = %i[
          add_index
          index
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          if add_index_without_concurrency?(node)
            add_offense(node) do |corrector|
              autocorrect(corrector, node)
            end
          end

          duplicated_disable_ddl_transactions_from(node).each do |disable_ddl_transactions_node|
            add_offense(node, message: MESSAGE_FOR_DUPLICATED_DISABLE_DDL_TRANSACTION) do |corrector|
              corrector.remove(
                range_with_surrounding_space(
                  disable_ddl_transactions_node.source_range,
                  side: :left
                )
              )
            end
          end
        end

        private

        # @!method add_index?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_index?, <<~PATTERN
          (send
            nil?
            :add_index
            _
            _
            ...
          )
        PATTERN

        # @!method add_index_concurrently?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_index_concurrently?, <<~PATTERN
          (send
            nil?
            :add_index
            _
            _
            (hash
              <
                (pair
                  (sym :algorithm)
                  (sym :concurrently)
                )
                ...
              >
            )
          )
        PATTERN

        # @!method index?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :index?, <<~PATTERN
          (send
            lvar
            :index
            _
            ...
          )
        PATTERN

        # @!method index_concurrently?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :index_concurrently?, <<~PATTERN
          (send
            lvar
            :index
            _
            (hash
              <
                (pair
                  (sym :algorithm)
                  (sym :concurrently)
                )
                ...
              >
            )
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def add_index_without_concurrency?(node)
          case node.method_name
          when :add_index
            add_index?(node) && !add_index_concurrently?(node)
          when :index
            index?(node) && in_change_table?(node) && !index_concurrently?(node)
          end
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          insert_disable_ddl_transaction(corrector, node) unless within_disable_ddl_transaction?(node)
          insert_algorithm_option(corrector, node)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Array<RuboCop::AST::SendNode>]
        def duplicated_disable_ddl_transactions_from(node)
          disable_ddl_transactions_from(node)[1..] || []
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def in_change_table?(node)
          node.each_ancestor(:block).first&.method?(:change_table)
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def insert_algorithm_option(
          corrector,
          node
        )
          target_node = node.last_argument
          target_node = target_node.pairs.last if target_node.hash_type?
          corrector.insert_after(
            target_node,
            ', algorithm: :concurrently'
          )
        end
      end
    end
  end
end
