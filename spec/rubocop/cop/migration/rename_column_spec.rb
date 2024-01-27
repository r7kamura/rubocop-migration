# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::RenameColumn, :config do
  context 'when `rename_column` is used' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class RenameUsersSettingsToProperties < ActiveRecord::Migration[7.0]
          def change
            rename_column :users, :settings, :properties
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid renaming columns that are in use.
          end
        end
      RUBY
    end
  end
end
