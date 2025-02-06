# frozen_string_literal: true

require 'set'

module RuboCop
  module Cop
    module Migration
      # Avoid using MySQL reserved words as identifiers.
      #
      # @example
      #   # bad
      #   # NOTE: `role` is a reserved word in MySQL.
      #   add_column :users, :role, :string
      #
      #   # good
      #   add_column :users, :some_other_good_name, :string
      class ReservedWordMysql < RuboCop::Cop::Base
        include ::RuboCop::Migration::CopConcerns::ColumnTypeMethod

        MSG = 'Avoid using MySQL reserved words as identifiers.'

        # Obtained from https://dev.mysql.com/doc/refman/8.4/en/keywords.html.
        PATH_TO_RESERVED_WORDS_FILE = File.expand_path(
          '../../../../data/reserved_words_mysql.txt',
          __dir__
        ).freeze

        RESTRICT_ON_SEND = [
          :add_column,
          :add_index,
          :add_reference,
          :create_join_table,
          :create_table,
          :rename,
          :rename_column,
          :rename_index,
          :rename_table,
          *COLUMN_TYPE_METHOD_NAMES
        ].freeze

        class << self
          # @return [Array<String>]
          def reserved_words
            @reserved_words ||= ::Set.new(
              ::File.read(PATH_TO_RESERVED_WORDS_FILE).split("\n")
            ).freeze
          end
        end

        # @param node [RuboCop::AST::DefNode]
        # @return [void]
        def on_send(node)
          offended_identifier_nodes_from(node).each do |identifier_node|
            add_offense(identifier_node)
          end
        end

        private

        # @!method index_name_option_from_add_index(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::Node, nil]
        def_node_matcher :index_name_option_from_add_index, <<~PATTERN
          (send
            nil?
            :add_index
            _
            _
            (hash
              <
                (pair
                  (sym :name)
                  $_
                )
              >
              ...
            )
          )
        PATTERN

        # @!method index_name_option_from_add_reference(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::Node, nil]
        def_node_matcher :index_name_option_from_add_reference, <<~PATTERN
          (send
            nil?
            :add_reference
            _
            _
            (hash
              <
                (pair
                  (sym :index)
                  (hash
                    <
                      (pair
                        (sym :name)
                        $_
                      )
                    >
                    ...
                  )
                )
              >
              ...
            )
          )
        PATTERN

        # @!method index_name_option_from_column_type(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::Node, nil]
        def_node_matcher :index_name_option_from_column_type, <<~PATTERN
          (send
            lvar
            COLUMN_TYPE_METHOD_NAMES
            _
            (hash
              <
                (pair
                  (sym :index)
                  (hash
                    <
                      (pair
                        (sym :name)
                        $_
                      )
                      ...
                    >
                  )
                )
                ...
              >
            )
          )
        PATTERN

        # @!method table_name_option_from(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::Node, nil]
        def_node_matcher :table_name_option_from, <<~PATTERN
          (send
            nil?
            :create_join_table
            _
            _
            (hash
              <
                (pair
                  (sym :table_name)
                  $_
                )
                ...
              >
            )
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Array<RuboCop::AST::Node>]
        def identifier_column_name_nodes_from(node)
          case node.method_name
          when :add_column, :rename
            [node.arguments[1]]
          when :rename_column
            [node.arguments[2]]
          when *COLUMN_TYPE_METHOD_NAMES
            [node.first_argument]
          else
            []
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Array<RuboCop::AST::Node>]
        def identifier_index_name_nodes_from(node)
          case node.method_name
          when :add_index
            [index_name_option_from_add_index(node)].compact
          when :add_reference
            [index_name_option_from_add_reference(node)].compact
          when :rename_index
            [node.arguments[2]]
          when *COLUMN_TYPE_METHOD_NAMES
            [index_name_option_from_column_type(node)].compact
          else
            []
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Array<RuboCop::AST::Node>]
        def identifier_nodes_from(node)
          identifier_table_name_nodes_from(node) +
            identifier_column_name_nodes_from(node) +
            identifier_index_name_nodes_from(node)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Array<RuboCop::AST::Node>]
        def identifier_table_name_nodes_from(node)
          case node.method_name
          when :create_join_table
            [table_name_option_from(node)].compact
          when :create_table
            [node.first_argument]
          when :rename_table
            [node.arguments[1]]
          else
            []
          end
        end

        # @param node [RuboCop::AST::Node]
        # @return [Array<RuboCop::AST::Node>]
        def offended_identifier_nodes_from(node)
          identifier_nodes_from(node).select do |identifier_node|
            reserved_word_identifier_node?(identifier_node)
          end
        end

        # @param node [RuboCop::AST::Node]
        # @return [Boolean]
        def reserved_word_identifier_node?(node)
          return false unless node.respond_to?(:value)

          self.class.reserved_words.include?(node.value.to_s)
        end
      end
    end
  end
end
