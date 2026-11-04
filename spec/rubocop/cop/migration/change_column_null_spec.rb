# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::ChangeColumnNull, :config do
  context 'when `change_column_null` is called in 2nd migration step' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def change
          validate_constraint :users, 'users_name_is_not_null'
          change_column_null :users, :name, false
          remove_check_constraint :users, name: 'users_name_is_not_null'
        end
      RUBY
    end
  end

  context 'when `t.change_null` is called in 2nd migration step' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def change
          validate_constraint :users, 'users_name_is_not_null'
          change_table :users do |t|
            t.change_null :name, false
            t.remove_check_constraint name: 'users_name_is_not_null'
          end
        end
      RUBY
    end
  end

  context 'when `change_column_null` is called after `validate_check_constraint`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def change
          validate_check_constraint :users, name: 'users_name_is_not_null'
          change_column_null :users, :name, false
          remove_check_constraint :users, name: 'users_name_is_not_null'
        end
      RUBY
    end
  end

  context 'when `t.change_null` is called after `validate_check_constraint`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def change
          validate_check_constraint :users, name: 'users_name_is_not_null'
          change_table :users do |t|
            t.change_null :name, false
            t.remove_check_constraint name: 'users_name_is_not_null'
          end
        end
      RUBY
    end
  end

  context 'when `change_column_null` allows NULL in `down`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def down
          change_column_null :users, :name, true
        end
      RUBY
    end
  end

  context 'when `t.change_null` allows NULL in `up`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def up
          change_table :users do |t|
            t.change_null :name, true
          end
        end
      RUBY
    end
  end

  context 'when `change_column_null` allows NULL in `change`' do
    it 'registers an offense without autocorrection, as its rollback sets NOT NULL' do
      expect_offense(<<~RUBY)
        def change
          change_column_null :users, :name, true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Allow NULL in `up` instead of `change`, as rolling back `change` simply sets `NOT NULL` constraint again.
        end
      RUBY

      expect_no_corrections
    end
  end

  context 'when `change_column_null` is simply called' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def change
          change_column_null :users, :name, false
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid simply setting `NOT NULL` constraint on an existing column in PostgreSQL.
        end
      RUBY

      expect_correction(<<~RUBY)
        def change
          add_check_constraint :users, 'name IS NOT NULL', name: 'users_name_is_not_null', validate: false
        end
      RUBY
    end
  end

  context 'when `t.change_null` is simply called' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def change
          change_table :users do |t|
            t.change_null :name, false
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid simply setting `NOT NULL` constraint on an existing column in PostgreSQL.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        def change
          change_table :users do |t|
            t.check_constraint 'name IS NOT NULL', name: 'users_name_is_not_null', validate: false
          end
        end
      RUBY
    end
  end
end
