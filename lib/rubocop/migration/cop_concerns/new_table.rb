# frozen_string_literal: true

module RuboCop
  module Migration
    module CopConcerns
      module NewTable
        class << self
          def included(klass)
            super
            klass.class_eval do
              # @!method create_table_if_not_exists?(node)
              #   @param node [RuboCop::AST::SendNode]
              #   @return [Boolean]
              def_node_matcher :create_table_if_not_exists?, <<~PATTERN
                (send
                  nil?
                  :create_table
                  _
                  (hash
                    <
                      (pair
                        (sym :if_not_exists)
                        true
                      )
                      ...
                    >
                  )
                )
              PATTERN

              # @!method create_table_name_from(node)
              #   @param node [RuboCop::AST::SendNode]
              #   @return [String, Symbol, nil]
              def_node_matcher :create_table_name_from, <<~PATTERN
                (send
                  nil?
                  :create_table
                  ({str sym} $_)
                  ...
                )
              PATTERN
            end
          end
        end

        private

        # @param node [RuboCop::AST::Node]
        # @param table_name [String]
        # @return [Boolean]
        def create_table_of?(
          node,
          table_name
        )
          node = node.send_node if node.block_type?
          node.send_type? &&
            create_table_name_from(node)&.to_s == table_name &&
            !create_table_if_not_exists?(node)
        end

        # Whether the table is created by a `create_table` written directly in the method body before it,
        # not under a condition, a block, or a rescue.
        # @param table_node [RuboCop::AST::Node, nil]
        # @return [Boolean]
        def new_table?(table_node)
          return false unless table_node&.type?(:str, :sym)

          body_node = table_node.each_ancestor(:def, :defs).first&.body
          return false unless body_node&.begin_type?

          table_name = table_node.value.to_s
          body_node.each_child_node.any? do |statement_node|
            statement_node.source_range.end_pos < table_node.source_range.begin_pos &&
              create_table_of?(statement_node, table_name)
          end
        end
      end
    end
  end
end
