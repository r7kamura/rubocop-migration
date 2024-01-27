# frozen_string_literal: true

require 'active_support/inflector'
require 'pathname'

module RuboCop
  module Cop
    module Migration
      # Make sure the column is already ignored by the running app before removing it.
      #
      # Active Record caches database columns at runtime, so if you drop a column, it can cause exceptions until your app reboots.
      #
      # @safety
      #   The logic to check if it is included in `ignored_columns` may fail.
      #
      # @example
      #   # bad
      #   class User < ApplicationRecord
      #   end
      #
      #   class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_column :users, :some_column
      #     end
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     self.ignored_columns += %w[some_column]
      #   end
      #
      #   class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_column :users, :some_column
      #     end
      #   end
      class RemoveColumn < RuboCop::Cop::Base
        MSG = 'Make sure the column is already ignored by the running app before removing it.'

        RESTRICT_ON_SEND = %i[
          remove_column
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node)
        end

        private

        # @!method ignored_columns?(node)
        #   @param node [RuboCop::AST::Node]
        #   @return [Boolean]
        def_node_matcher :ignored_columns?, <<~PATTERN
          (send
            self
            :ignored_columns
            ...
          )
        PATTERN

        # @!method remove_column?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :remove_column?, <<~PATTERN
          (send
            nil?
            :remove_column
            ...
          )
        PATTERN

        # @!method ignored_column_nodes_from(node)
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<String, Symbol>, nil]
        def_node_matcher :ignored_column_nodes_from, <<~PATTERN
          `{
            (op_asgn
              (send
                self
                :ignored_columns
                ...
              )
              :+
              (array
                ({str sym} $_)*
              )
            )

            (send
              self
              :ignored_columns=
              (array
                ({str sym} $_)*
              )
            )
          }
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          remove_column?(node) &&
            !ignored?(node)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String, nil]
        def find_column_name_from(node)
          node.arguments[1].value&.to_s
        end

        # @param table_name [String]
        # @return [Array<String>]
        def find_ignored_column_names_from(table_name)
          pathname = model_pathname_from(
            singularize(table_name)
          )
          return [] unless pathname.exist?

          ignored_column_nodes = ignored_column_nodes_from(
            parse(
              content: pathname.read,
              path: pathname.to_s
            )
          )
          return [] unless ignored_column_nodes

          ignored_column_nodes.map(&:to_s)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [String, nil]
        def find_table_name_from(node)
          table_name_node = node.first_argument
          table_name_node.value&.to_s if table_name_node.respond_to?(:value)
        end

        # @note This method returns `true` if the table name cannot be determined.
        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def ignored?(node)
          table_name = find_table_name_from(node)
          return true unless table_name

          find_ignored_column_names_from(table_name).include?(
            find_column_name_from(node)
          )
        end

        # @param snake_cased_model_name [String]
        # @return [Pathname]
        def model_pathname_from(snake_cased_model_name)
          ::Pathname.new("app/models/#{snake_cased_model_name}.rb")
        end

        # @param content [String]
        # @param path [String]
        # @return [RuboCop::AST::Node]
        def parse(
          content:,
          path:
        )
          Parser.call(
            content: content,
            path: path,
            target_ruby_version: target_ruby_version
          )
        end

        # @param plural [String]
        # @return [String]
        def singularize(plural)
          ::ActiveSupport::Inflector.singularize(plural)
        end

        class Parser
          class << self
            # @param content [String]
            # @param path [String]
            # @param target_ruby_version [#to_s]
            # @return [RuboCop::AST::Node]
            def call(
              content:,
              path:,
              target_ruby_version:
            )
              new(
                content: content,
                path: path,
                target_ruby_version: target_ruby_version
              ).call
            end
          end

          # @param content [String]
          # @param path [String]
          # @param target_ruby_version [#to_s]
          def initialize(
            content:,
            path:,
            target_ruby_version:
          )
            @content = content
            @path = path
            @target_ruby_version = target_ruby_version
          end

          # @return [RuboCop::AST::Node]
          def call
            parser.parse(buffer)
          end

          private

          # @return [Parser::Source::Buffer]
          def buffer
            ::Parser::Source::Buffer.new(
              @path,
              source: @content
            )
          end

          # @return [RuboCop::AST::Builder]
          def builder
            ::RuboCop::AST::Builder.new
          end

          def parser
            parser_class.new(builder)
          end

          # @return [Class]
          def parser_class
            ::Parser.const_get(parser_class_name)
          end

          # @return [String]
          def parser_class_name
            "Ruby#{@target_ruby_version.to_s.delete('.')}"
          end
        end
      end
    end
  end
end
