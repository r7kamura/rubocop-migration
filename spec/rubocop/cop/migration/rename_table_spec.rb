# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::RenameTable, :config do
  context 'when `rename_table` is used' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class RenameUsersToAccouts < ActiveRecord::Migration[7.0]
          def change
            rename_table :users, :accounts
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid renaming tables that are in use.
          end
        end
      TEXT
    end
  end
end
