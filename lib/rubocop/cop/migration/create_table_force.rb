# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Create tables without `force: true` option.
      #
      # The `force: true` option can drop an existing table.
      # If you indend to drop an existing table, explicitly call `drop_table` first.
      #
      # @example
      #   # bad
      #   class CreateUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       create_table :users, force: true
      #     end
      #   end
      #
      #   # good
      #   class CreateUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       create_table :users
      #     end
      #   end
      class CreateTableForce < RuboCop::Cop::Base
        extend AutoCorrector

        include RangeHelp

        MSG = 'Create tables without `force: true` option.'

        RESTRICT_ON_SEND = %i[
          create_table
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          option_node = option_force_true_from_create_table(node)
          return unless option_node

          add_offense(option_node) do |corrector|
            autocorrect(corrector, option_node)
          end
        end

        private

        # @!method option_force_true_from_create_table(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::PairNode, nil]
        def_node_matcher :option_force_true_from_create_table, <<~PATTERN
          (send
            nil?
            :create_table
            _
            (hash
              <
                $(pair
                  (sym :force)
                  true
                )
                ...
              >
            )
          )
        PATTERN

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::PairNode]
        # @return [void]
        def autocorrect(
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
      end
    end
  end
end
