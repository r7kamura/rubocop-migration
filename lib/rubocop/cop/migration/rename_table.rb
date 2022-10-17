# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Avoid renaming tables that are in use.
      #
      # It will cause errors in your application.
      # A safer approach is to:
      #
      # 1. Create a new table
      # 2. Write to both tables
      # 3. Backfill data from the old table to new table
      # 4. Move reads from the old table to the new table
      # 5. Stop writing to the old table
      # 6. Drop the old table
      #
      # @safety
      #   Only meaningful if the table is in use.
      #
      # @example
      #   # bad
      #   class RenameUsersToAccouts < ActiveRecord::Migration[7.0]
      #     def change
      #       rename_table :users, :accounts
      #     end
      #   end
      #
      #   # good
      #   class AddAccounts < ActiveRecord::Migration[7.0]
      #     def change
      #       create_table :accounts do |t|
      #         t.string :name, null: false
      #       end
      #     end
      #   end
      #
      #   class RemoveUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_table :users
      #     end
      #   end
      class RenameTable < RuboCop::Cop::Base
        MSG = 'Avoid renaming tables that are in use.'

        RESTRICT_ON_SEND = %i[
          rename_table
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node)
        end

        private

        # @!method rename_table?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :rename_table?, <<~PATTERN
          (send
            nil?
            :rename_table
            ...
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          rename_table?(node)
        end
      end
    end
  end
end
