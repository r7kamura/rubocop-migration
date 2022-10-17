# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::ChangeColumnNull, :config do
  context 'when `change_column_null` is called in 2nd migration step' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def change
          validate_constraint :users, :name, name: 'users_name_is_not_null'
          change_column_null :users, :name, false
          remove_check_constraint :users, name: 'users_name_is_not_null'
        end
      RUBY
    end
  end

  context 'when `change_column_null` is simply called' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        def change
          change_column_null :users, :name, false
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid simply setting `NOT NULL` constraint on an existing column in PostgreSQL.
        end
      TEXT

      expect_correction(<<~RUBY)
        def change
          add_check_constraint :users, 'name IS NOT NULL', name: 'users_name_is_not_null', validate: false
        end
      RUBY
    end
  end
end
