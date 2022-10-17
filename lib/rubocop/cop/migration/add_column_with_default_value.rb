# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Add the column without a default value then change the default.
      #
      # In earlier versions of Postgres, MySQL, and MariaDB,
      # adding a column with a default value to an existing table causes the entire table to be rewritten.
      # During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.
      #
      # @safety
      #   Only meaningful in earlier versions of Postgres, MySQL, and MariaDB.
      #
      # @example
      #   # bad
      #   class AddSomeColumnToUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :some_column, :string, default: 'some value'
      #     end
      #   end
      #
      #   # good
      #   class AddSomeColumnToUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :some_column, :string
      #       change_column_default :users, :some_column, 'some value'
      #     end
      #   end
      class AddColumnWithDefaultValue < RuboCop::Cop::Base
        extend AutoCorrector

        include RangeHelp
        include ::RuboCop::Migration::CopConcerns::ColumnTypeMethod

        MSG = 'Add the column without a default value then change the default.'

        RESTRICT_ON_SEND = [
          :add_column,
          *COLUMN_TYPE_METHOD_NAMES
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless target_method?(node)

          default_option_node = non_nil_default_option_node_from(node)
          return unless default_option_node

          add_offense(default_option_node) do |corrector|
            autocorrect(
              corrector,
              default_option_node: default_option_node,
              send_node: node
            )
          end
        end

        private

        # @!method add_column?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_column?, <<~PATTERN
          (send
            nil?
            :add_column
            ...
          )
        PATTERN

        # @!method column_type_method?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :column_type_method?, <<~PATTERN
          (send
            lvar
            COLUMN_TYPE_METHOD_NAMES
            ...
          )
        PATTERN

        # @!method non_nil_default_option_node_from(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::PairNode, nil]
        def_node_matcher :non_nil_default_option_node_from, <<~PATTERN
          (send
            _
            _
            ...
            (hash
              <
                $(pair
                  (sym :default)
                  !nil
                )
              >
              ...
            )
          )
        PATTERN

        # @param corrector [RuboCop::Cop::Corrector]
        # @param default_option_node [RuboCop::AST::PairNode]
        # @param send_node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          default_option_node:,
          send_node:
        )
          remove_pair(
            corrector,
            default_option_node
          )
          insert_change_column_default(
            corrector,
            default_option_node: default_option_node,
            send_node: send_node
          )
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::SymNode]
        def find_column_node_from(node)
          case node.method_name
          when :add_column
            node.arguments[1]
          else
            node.first_argument
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::SendNode]
        def find_insertion_target_node_from(node)
          case node.method_name
          when :add_column
            node
          else
            node.each_ancestor(:block).first
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::SymNode]
        def find_table_node_from(node)
          case node.method_name
          when :add_column
            node.first_argument
          else
            node.each_ancestor(:block).first.send_node.first_argument
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def in_change_table?(node)
          node.each_ancestor(:block).first&.method?(:change_table)
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::Node]
        # @param string [String]
        def insert_after_with_same_indentation(
          corrector,
          node,
          string
        )
          corrector.insert_after(
            node,
            format(
              "\n%<indentation>s%<string>s",
              indentation: ' ' * node.location.column,
              string: string
            )
          )
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param default_option_node [RuboCop::AST::PairNode]
        # @param send_node [RuboCop::AST::SendNode]
        # @return [void]
        def insert_change_column_default(
          corrector,
          default_option_node:,
          send_node:
        )
          insert_after_with_same_indentation(
            corrector,
            find_insertion_target_node_from(send_node),
            format(
              'change_column_default %<table>s, %<column>s, %<default>s',
              column: find_column_node_from(send_node).source,
              default: default_option_node.value.source,
              table: find_table_node_from(send_node).source
            )
          )
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::Node]
        # @return [void]
        def remove_pair(
          corrector,
          node
        )
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.location.expression,
                side: :left
              ),
              :left
            )
          )
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def target_method?(node)
          add_column?(node) ||
            (column_type_method?(node) && in_change_table?(node))
        end
      end
    end
  end
end
