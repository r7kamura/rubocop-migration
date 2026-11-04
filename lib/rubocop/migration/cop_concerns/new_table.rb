# frozen_string_literal: true

module RuboCop
  module Migration
    module CopConcerns
      module NewTable
        class << self
          def included(klass)
            super
            klass.class_eval do
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

        # @param node [RuboCop::AST::SendNode]
        # @param table_node [RuboCop::AST::Node, nil]
        # @return [Boolean]
        def new_table?(
          node,
          table_node
        )
          return false unless table_node&.type?(:str, :sym)

          definition_node = node.each_ancestor(:def, :defs).first
          return false unless definition_node

          definition_node.each_descendant(:send).any? do |send_node|
            send_node.source_range.begin_pos < node.source_range.begin_pos &&
              create_table_name_from(send_node)&.to_s == table_node.value.to_s &&
              unconditional_within?(send_node, definition_node)
          end
        end

        # @param node [RuboCop::AST::Node]
        # @param definition_node [RuboCop::AST::DefNode]
        # @return [Boolean]
        def unconditional_within?(
          node,
          definition_node
        )
          node.each_ancestor.take_while { |ancestor| !ancestor.equal?(definition_node) }.none? do |ancestor|
            ancestor.conditional? || ancestor.operator_keyword?
          end
        end
      end
    end
  end
end
