# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Activate a check constraint in a separate migration in PostgreSQL.
      #
      # Adding a check constraint without `NOT VALID` blocks reads and writes in Postgres and
      # blocks writes in MySQL and MariaDB while every row is checked.
      #
      # @safety
      #   Only meaningful in PostgreSQL.
      #
      # @example
      #   # bad
      #   class AddCheckConstraintToOrdersPrice < ActiveRecord::Migration[7.0]
      #     def change
      #       add_check_constraint :orders, 'price > 0', name: 'orders_price_positive'
      #     end
      #   end
      #
      #   # good
      #   class AddCheckConstraintToOrdersPriceWithoutValidation < ActiveRecord::Migration[7.0]
      #     def change
      #       add_check_constraint :orders, 'price > 0', name: 'orders_price_positive', validate: false
      #     end
      #   end
      #
      #   class ActivateCheckConstraintOnOrdersPrice < ActiveRecord::Migration[7.0]
      #     def change
      #       validate_check_constraint :orders, name: 'orders_price_positive'
      #     end
      #   end
      class AddCheckConstraint < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Activate a check constraint in a separate migration in PostgreSQL.'

        RESTRICT_ON_SEND = %i[
          add_check_constraint
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_csend on_send

        private

        # @!method add_check_constraint?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_check_constraint?, <<~PATTERN
          (send
            nil?
            :add_check_constraint
            ...
          )
        PATTERN

        # @!method add_check_constraint_with_validate_false?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_check_constraint_with_validate_false?, <<~PATTERN
          (send
            nil?
            :add_check_constraint
            _
            _
            (hash
              <
                (pair
                  (sym :validate)
                  false
                )
                ...
              >
            )
          )
        PATTERN

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          target = node.last_argument
          target = target.pairs.last if target.hash_type?
          corrector.insert_after(
            target,
            ', validate: false'
          )
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          add_check_constraint?(node) &&
            !add_check_constraint_with_validate_false?(node)
        end
      end
    end
  end
end
