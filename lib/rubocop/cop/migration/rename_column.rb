# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Avoid renaming columns that are in use.
      #
      # It will cause errors in your application.
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
      #   Only meaningful if the column is in use.
      #
      # @example
      #   # bad
      #   class RenameUsersSettingsToProperties < ActiveRecord::Migration[7.0]
      #     def change
      #       rename_column :users, :settings, :properties
      #     end
      #   end
      #
      #   # good
      #   class AddUsersProperties < ActiveRecord::Migration[7.0]
      #     def change
      #       add_column :users, :properties, :jsonb
      #     end
      #   end
      #
      #   class User < ApplicationRecord
      #     self.ignored_columns += %w[settings]
      #   end
      #
      #   class RemoveUsersSettings < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_column :users, :settings
      #     end
      #   end
      class RenameColumn < RuboCop::Cop::Base
        MSG = 'Avoid renaming columns that are in use.'

        RESTRICT_ON_SEND = %i[
          rename_column
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          return unless bad?(node)

          add_offense(node)
        end
        alias on_csend on_send

        private

        # @!method rename_column?(node)
        #   @param node [RuboCop::AST::SendNode]
        #   @return [Boolean]
        def_node_matcher :rename_column?, <<~PATTERN
          (send
            nil?
            :rename_column
            ...
          )
        PATTERN

        # @param node [RuboCop::AST::SendNode]
        # @return [Boolean]
        def bad?(node)
          rename_column?(node)
        end
      end
    end
  end
end
