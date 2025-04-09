# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Avoid changing column type that is in use.
      #
      # Changing the type of a column causes the entire table to be rewritten.
      # During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.
      #
      # Some changes don’t require a table rewrite and are safe in PostgreSQL:
      #
      # Type | Safe Changes
      # --- | ---
      # `cidr` | Changing to `inet`
      # `citext` | Changing to `text` if not indexed, changing to `string` with no `:limit` if not indexed
      # `datetime` | Increasing or removing `:precision`, changing to `timestamptz` when session time zone is UTC in Postgres 12+
      # `decimal` | Increasing `:precision` at same `:scale`, removing `:precision` and `:scale`
      # `interval` | Increasing or removing `:precision`
      # `numeric` | Increasing `:precision` at same `:scale`, removing `:precision` and `:scale`
      # `string` | Increasing or removing `:limit`, changing to `text`, changing `citext` if not indexed
      # `text` | Changing to `string` with no `:limit`, changing to `citext` if not indexed
      # `time` | Increasing or removing `:precision`
      # `timestamptz` | Increasing or removing `:limit`, changing to `datetime` when session time zone is UTC in Postgres 12+
      #
      # And some in MySQL and MariaDB:
      #
      # Type | Safe Changes
      # --- | ---
      # `string` | Increasing `:limit` from under 255 up to 255, increasing `:limit` from over 255 to the max
      #
      # A safer approach is to:
      #
      # 1. Create a new column
      # 2. Write to both columns
      # 3. Backfill data from the old column to the new column
      # 4. Move reads from the old column to the new column
      # 5. Stop writing to the old column
      # 6. Drop the old column
      #
      # @safety
      #   Only meaningful if the table is in use and the type change is really unsafe as described above.
      #
      # @example
      #   # bad
      #   class ChangeUsersSomeColumnType < ActiveRecord::Migration[7.0]
      #     def change
      #       change_column :users, :some_column, :new_type
      #     end
      #   end
      #
      #   # good
      #   class AddUsersAnotherColumn < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :another_column, :new_type
      #     end
      #   end
      #
      #   class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_column :users, :some_column
      #     end
      #   end
      class ChangeColumn < RuboCop::Cop::Base
        MSG = 'Avoid changing column type that is in use.'

        RESTRICT_ON_SEND = %i[
          change
          change_column
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node)
        end
        alias on_csend on_send

        private

        # @!method change?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :change?, <<~PATTERN
          (send
            lvar
            :change
            ...
          )
        PATTERN

        # @!method change_column?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :change_column?, <<~PATTERN
          (send
            nil?
            :change_column
            ...
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          change?(node) ||
            change_column?(node)
        end
      end
    end
  end
end
