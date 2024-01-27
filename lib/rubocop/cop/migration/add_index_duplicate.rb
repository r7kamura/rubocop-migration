# frozen_string_literal: true

require 'rubocop/rails/schema_loader'
require 'rubocop/rails/schema_loader/schema'

module RuboCop
  module Cop
    module Migration
      # Avoid adding duplicate indexes.
      #
      # @safety
      #   This cop tries to find existing indexes from db/schema.rb, but it cannnot be found.
      #
      # @example
      #   # bad
      #   class AddIndexToUsersNameAndEmail < ActiveRecord::Migration[7.0]
      #     def change
      #       add_index :users, %w[name index]
      #     end
      #   end
      #
      #   class AddIndexToUsersName < ActiveRecord::Migration[7.0]
      #     def change
      #       add_index :users, :name
      #     end
      #   end
      class AddIndexDuplicate < RuboCop::Cop::Base
        MSG = 'Avoid adding duplicate indexes.'

        RESTRICT_ON_SEND = %i[
          add_index
          index
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node)
        end

        private

        # @!method add_index?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_index?, <<~PATTERN
          (send
            nil?
            :add_index
            ...
          )
        PATTERN

        # @!method index?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :index?, <<~PATTERN
          (send
            lvar
            :index
            ...
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def adding_duplicated_index?(node)
          indexed_column_names = indexed_column_names_from(node)
          return false unless indexed_column_names

          table_name = table_name_from(node)
          return false unless table_name

          existing_indexes_for(table_name).any? do |existing_index_column_names|
            leftmost_match?(
              haystack: existing_index_column_names,
              needle: indexed_column_names
            )
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          return false unless target_method?(node)

          adding_duplicated_index?(node)
        end

        # @param table_name [String]
        # @return [Array<String>]
        def existing_indexes_for(table_name)
          return [] unless schema

          table = schema.table_by(name: table_name)
          return [] unless table

          table.indices.map do |index|
            index.columns.map(&:to_s)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Array<String>, nil]
        def indexed_column_names_from(node)
          indexed_columns_node = indexed_columns_node_from(node)
          case indexed_columns_node&.type
          when :array
            indexed_columns_node.children.map { |child| child.value.to_s }
          when :str, :sym
            [indexed_columns_node.value.to_s]
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::Node, nil]
        def indexed_columns_node_from(node)
          case node.method_name
          when :add_index
            node.arguments[1]
          when :index
            node.first_argument
          end
        end

        # @param haystack [Array<String>]
        # @param needle [Array<String>]
        # @return [Boolean]
        def leftmost_match?(
          haystack:,
          needle:
        )
          haystack.join(',').start_with?(needle.join(','))
        end

        # @return [RuboCop::Rails::SchemaLoader::Schema, nil]
        def schema
          @schema ||= ::RuboCop::Rails::SchemaLoader.load(target_ruby_version)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String, nil]
        def table_name_from(node)
          table_name_value_node = table_name_value_node_from(node)
          return unless table_name_value_node.respond_to?(:value)

          table_name_value_node.value.to_s
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::Node, nil]
        def table_name_value_node_from(node)
          case node.method_name
          when :add_index
            table_name_value_node_from_add_index(node)
          when :index
            table_name_value_node_from_index(node)
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::Node, nil]
        def table_name_value_node_from_add_index(node)
          node.first_argument
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::Node, nil]
        def table_name_value_node_from_index(node)
          node.each_ancestor(:block).first&.send_node&.first_argument
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def target_method?(node)
          add_index?(node) || index?(node)
        end
      end
    end
  end
end
