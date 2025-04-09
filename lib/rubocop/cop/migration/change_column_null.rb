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
          change_null
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return if called_with_validate_constraint?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_csend on_send

        private

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
          case node.method_name
          when :change_column_null
            autocorrect_change_column_null(corrector, node)
          when :change_null
            autocorrect_change_null(corrector, node)
          end
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect_change_column_null(
          corrector,
          node
        )
          corrector.replace(
            node,
            format_add_check_constraint(
              column_name: find_column_name_from_change_column_null(node),
              table_name: find_table_name_from_change_column_null(node)
            )
          )
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect_change_null(
          corrector,
          node
        )
          corrector.replace(
            node.location.selector.with(
              end_pos: node.source_range.end_pos
            ),
            format_check_constraint(
              column_name: find_column_name_from_change_null(node),
              table_name: find_table_name_from_change_null(node)
            )
          )
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def called_with_validate_constraint?(node)
          case node.method_name
          when :change_column_null
            node
          when :change_null
            find_ancestor_change_table(node)
          end.left_siblings.any? do |sibling|
            validate_constraint?(sibling)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::BlockNode]
        def find_ancestor_change_table(node)
          node.each_ancestor(:block).find do |ancestor|
            ancestor.method?(:change_table)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String]
        def find_column_name_from_change_column_null(node)
          node.arguments[1].value.to_s
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String]
        def find_column_name_from_change_null(node)
          node.first_argument.value.to_s
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String]
        def find_table_name_from_change_column_null(node)
          node.first_argument.value.to_s
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String]
        def find_table_name_from_change_null(node)
          find_ancestor_change_table(node).send_node.first_argument.value.to_s
        end

        # @param column_name [String]
        # @param table_name [String]
        # @return [String]
        def format_add_check_constraint(
          column_name:,
          table_name:
        )
          format(
            'add_check_constraint :%<table_name>s, %<arguments>s',
            arguments: format_check_constraint_arguments(
              column_name: column_name,
              table_name: table_name
            ),
            table_name: table_name
          )
        end

        # @param column_name [String]
        # @param table_name [String]
        # @return [String]
        def format_check_constraint(
          column_name:,
          table_name:
        )
          format(
            'check_constraint %<arguments>s',
            arguments: format_check_constraint_arguments(
              column_name: column_name,
              table_name: table_name
            )
          )
        end

        # @param coumn_name [String]
        # @param table_name [String]
        # @return [String]
        def format_check_constraint_arguments(
          column_name:,
          table_name:
        )
          format(
            "'%<column_name>s IS NOT NULL', name: '%<constraint_name>s', validate: false",
            column_name: column_name,
            constraint_name: "#{table_name}_#{column_name}_is_not_null"
          )
        end
      end
    end
  end
end
