# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Avoid simply setting `NOT NULL` constraint on an existing column in PostgreSQL.
      #
      # It blocks reads and writes while every row is checked.
      # In PostgreSQL 12+, you can safely set `NOT NULL` constraint if corresponding check constraint exists.
      #
      # @safety
      #   Only meaningful in PostgreSQL 12+.
      #
      # @example
      #   # bad
      #   class SetNotNullColumnConstraintToUsersName < ActiveRecord::Migration[7.0]
      #     def change
      #       change_column_null :users, :name, false
      #     end
      #   end
      #
      #   # good
      #   class SetNotNullCheckConstraintToUsersName < ActiveRecord::Migration[7.0]
      #     def change
      #       add_check_constraint :users, 'name IS NOT NULL', name: 'users_name_is_not_null', validate: false
      #     end
      #   end
      #
      #   class ReplaceNotNullConstraintOnUsersName < ActiveRecord::Migration[7.0]
      #     def change
      #       validate_constraint :users, name: 'users_name_is_not_null'
      #       change_column_null :users, :name, false
      #       remove_check_constraint :users, name: 'users_name_is_not_null'
      #     end
      #   end
      class ChangeColumnNull < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Avoid simply setting `NOT NULL` constraint on an existing column in PostgreSQL.'

        RESTRICT_ON_SEND = %i[
          change_column_null
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return if in_second_migration?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        # @!method parse_table_name_and_column_name(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Array<Symbol>, nil]
        def_node_matcher :parse_table_name_and_column_name, <<~PATTERN
          (send
            nil?
            _
            ({str sym} $_)
            ({str sym} $_)
            ...
          )
        PATTERN

        # @!method remove_check_constraint?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :remove_check_constraint?, <<~PATTERN
          (send nil? :remove_check_constraint ...)
        PATTERN

        # @!method validate_constraint?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :validate_constraint?, <<~PATTERN
          (send nil? :validate_constraint ...)
        PATTERN

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          table_name, column_name = parse_table_name_and_column_name(node)
          corrector.replace(
            node,
            format(
              "add_check_constraint :%<table>s, '%<column>s IS NOT NULL', name: '%<constraint>s', validate: false",
              column: column_name,
              constraint: "#{table_name}_#{column_name}_is_not_null",
              table: table_name
            )
          )
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def called_after_validate_constraint?(node)
          node.left_siblings.any? do |sibling|
            validate_constraint?(sibling)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def called_before_remove_check_constraint?(node)
          node.right_siblings.any? do |sibling|
            remove_check_constraint?(sibling)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def in_second_migration?(node)
          called_after_validate_constraint?(node) ||
            called_before_remove_check_constraint?(node)
        end
      end
    end
  end
end
