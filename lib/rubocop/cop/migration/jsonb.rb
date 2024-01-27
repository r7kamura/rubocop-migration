# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Prefer `jsonb` to `json`.
      #
      # In PostgreSQL, there is no equality operator for the json column type,
      # which can cause errors for existing `SELECT DISTINCT` queries in your application.
      #
      # @safety
      #   Only meaningful in PostgreSQL.
      #
      # @example
      #   # bad
      #   add_column :users, :properties, :json
      #
      #   # good
      #   add_column :users, :properties, :jsonb
      class Jsonb < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Prefer `jsonb` to `json`.'

        RESTRICT_ON_SEND = %i[
          add_column
          change
          change_column
          json
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          json_range = json_range_from_target_send_node(node)
          return unless json_range

          add_offense(json_range) do |corrector|
            corrector.replace(json_range, 'jsonb')
          end
        end

        private

        # @!method json_type_node_from_add_column(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::SymNode, nil]
        def_node_matcher :json_type_node_from_add_column, <<~PATTERN
          (send
            nil?
            _
            _
            _
            $(sym :json)
          )
        PATTERN
        alias json_type_node_from_change_column json_type_node_from_add_column

        # @!method json_type_node_from_change(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::SymNode, nil]
        def_node_matcher :json_type_node_from_change, <<~PATTERN
          (send
            lvar
            _
            _
            $(sym :json)
          )
        PATTERN

        # @!method json_type_node_from_json(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::SendNode, nil]
        def_node_matcher :json_type_node_from_json, <<~PATTERN
          $(send
            lvar
            _
            ...
          )
        PATTERN

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode, RuboCop::AST::SymNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          corrector.replace(node, 'jsonb')
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::SymNode, nil]
        def json_node_from_target_send_node(node)
          case node.method_name
          when :add_column
            json_type_node_from_add_column(node)
          when :change
            json_type_node_from_change(node)
          when :change_column
            json_type_node_from_change_column(node)
          when :json
            json_type_node_from_json(node)
          end
        end

        # @param node [RuboCop::AST::SendNode, RuboCop::AST::SymNode]
        # @return [Parser::Source::Range]
        def json_range_from_json_node(node)
          case node.type
          when :send
            node.location.selector
          when :sym
            node.source_range.with(
              begin_pos: node.source_range.begin_pos + 1
            )
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Parser::Source::Range]
        def json_range_from_target_send_node(node)
          json_node = json_node_from_target_send_node(node)
          return unless json_node

          json_range_from_json_node(json_node)
        end
      end
    end
  end
end
