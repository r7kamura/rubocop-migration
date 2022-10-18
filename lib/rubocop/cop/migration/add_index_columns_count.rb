# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Keep non-unique index columns count less than a specified number.
      #
      # Adding a non-unique index with more than three columns rarely improves performance.
      # Instead, start an index with columns that narrow down the results the most.
      #
      # @example
      #   # bad
      #   add_index :users, %i[a b c d]
      #
      #   # good (`MaxColumnsCount: 3` by default)
      #   add_index :users, %i[a b c]
      class AddIndexColumnsCount < RuboCop::Cop::Base
        RESTRICT_ON_SEND = %i[
          add_index
          index
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return if with_unique_option?(node)

          column_names_node = column_names_node_from(node)
          return unless column_names_node

          column_names_count = columns_count_from(column_names_node)
          return if column_names_count <= max_columns_count

          add_offense(
            column_names_node,
            message: "Keep unique index columns count less than #{max_columns_count}."
          )
        end

        private

        # @!method column_names_node_from_add_index(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::Node, nil]
        def_node_matcher :column_names_node_from_add_index, <<~PATTERN
          (send
            nil?
            :add_index
            _
            $({array | str | sym} ...)
            ...
          )
        PATTERN

        # @!method column_names_node_from_index(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::Node, nil]
        def_node_matcher :column_names_node_from_index, <<~PATTERN
          (send
            lvar
            :index
            $({array | str | sym} ...)
            ...
          )
        PATTERN

        # @!method with_unique_option?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :with_unique_option?, <<~PATTERN
          (send
            ...
            (hash
              <
                (pair
                  (sym :unique)
                  true
                )
                ...
              >
            )
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::Node, nil]
        def column_names_node_from(node)
          case node.method_name
          when :add_index
            column_names_node_from_add_index(node)
          when :index
            column_names_node_from_index(node)
          end
        end

        # @param node [RuboCop::AST::Node]
        # @return [Integer, nil]
        def columns_count_from(node)
          case node.type
          when :array
            node.values.count
          when :sym
            1
          end
        end

        # @return [Integer]
        def max_columns_count
          cop_config['MaxColumnsCount']
        end
      end
    end
  end
end
