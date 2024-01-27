# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Activate foreign key validation in a separate migration in PostgreSQL.
      #
      # To avoid blocking writes on both tables.
      #
      # @safety
      #   Only meaningful in PostgreSQL.
      #
      # @example
      #   # bad
      #   class AddForeignKeyFromArticlesToUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       add_foreign_key :articles, :users
      #     end
      #   end
      #
      #   # good
      #   class AddForeignKeyFromArticlesToUsersWithoutValidation < ActiveRecord::Migration[7.0]
      #     def change
      #       add_foreign_key :articles, :users, validate: false
      #     end
      #   end
      #
      #   class ActivateForeignKeyValidationFromArticlesToUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       validate_foreign_key :articles, :users
      #     end
      #   end
      class AddForeignKey < RuboCop::Cop::Base
        extend AutoCorrector

        include RangeHelp

        MSG = 'Activate foreign key validation in a separate migration in PostgreSQL.'

        RESTRICT_ON_SEND = %i[
          add_foreign_key
          add_reference
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        # @!method add_foreign_key_without_validate_option?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :add_foreign_key_without_validate_option?, <<~PATTERN
          (send
            nil?
            :add_foreign_key
            _
            _
            (hash
              (pair
                !(sym :validate)
                _
              )*
            )?
          )
        PATTERN

        # @!method option_validate_true_value_node_from_add_foreign_key(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::PairNode]
        def_node_matcher :option_validate_true_value_node_from_add_foreign_key, <<~PATTERN
          (send
            nil?
            :add_foreign_key
            _
            _
            (hash
              <
                (pair
                  (sym :validate)
                  $true
                )
                ...
              >
            )
          )
        PATTERN

        # @!method option_foreign_key_true_node_from_add_reference(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [RuboCop::AST::PairNode]
        def_node_matcher :option_foreign_key_true_node_from_add_reference, <<~PATTERN
          (send
            nil?
            :add_reference
            _
            _
            (hash
              <
                $(pair
                  (sym :foreign_key)
                  true
                )
                ...
              >
            )
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def add_foreign_key_with_validate_option_true?(node)
          option_validate_true_value_node_from_add_foreign_key(node)
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def add_reference_with_validate_option_true?(node)
          option_foreign_key_true_node_from_add_reference(node)
        end

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def autocorrect(
          corrector,
          node
        )
          if add_foreign_key_without_validate_option?(node)
            corrector.insert_after(node.last_argument, ', validate: false')
          elsif add_foreign_key_with_validate_option_true?(node)
            corrector.replace(
              option_validate_true_value_node_from_add_foreign_key(node),
              'false'
            )
          elsif add_reference_with_validate_option_true?(node)
            corrector.remove(
              range_with_surrounding_comma(
                range_with_surrounding_space(
                  option_foreign_key_true_node_from_add_reference(node).source_range,
                  side: :left
                ),
                :left
              )
            )
          end
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          add_foreign_key_without_validate_option?(node) ||
            add_foreign_key_with_validate_option_true?(node) ||
            add_reference_with_validate_option_true?(node)
        end
      end
    end
  end
end
