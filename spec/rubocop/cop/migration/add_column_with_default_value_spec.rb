# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::AddColumnWithDefaultValue, :config do
  context 'when `add_column` is used without `:default` option' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_column :users, :some_column, :string
      RUBY
    end
  end

  context 'when `add_column` is used with `default: nil`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_column :users, :some_column, :string, default: nil
      RUBY
    end
  end

  context 'when `t.string` is used with non-nil `default` option in `create_table`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        create_table :users do |t|
          t.string :some_column, default: 'some value'
        end
      RUBY
    end
  end

  context 'when `add_column` is used with non-nil `:default` option' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_column :users, :some_column, :string, default: 'some value'
                                                  ^^^^^^^^^^^^^^^^^^^^^ Add the column without a default value then change the default.
      RUBY

      expect_correction(<<~RUBY)
        add_column :users, :some_column, :string
        change_column_default :users, :some_column, 'some value'
      RUBY
    end
  end

  context 'when `t.string` is used with non-nil `:default` option in `change_table`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        change_table :users do |t|
          t.string :some_column, default: 'some value'
                                 ^^^^^^^^^^^^^^^^^^^^^ Add the column without a default value then change the default.
        end
      RUBY

      expect_correction(<<~RUBY)
        change_table :users do |t|
          t.string :some_column
        end
        change_column_default :users, :some_column, 'some value'
      RUBY
    end
  end

  context 'when `add_column` is used with non-nil `:default` option after `create_table` of the same table' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :users do |t|
              t.string :name
            end
            add_column :users, :some_column, :string, default: 'some value'
          end
        end
      RUBY
    end
  end

  context 'when `t.string` is used with non-nil `:default` option in `change_table` after `create_table` of the same table' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :users
            change_table :users do |t|
              t.string :some_column, default: 'some value'
            end
          end
        end
      RUBY
    end
  end

  context 'when `add_column` is used with non-nil `:default` option after `create_table` of another table' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :posts
            add_column :users, :some_column, :string, default: 'some value'
                                                      ^^^^^^^^^^^^^^^^^^^^^ Add the column without a default value then change the default.
          end
        end
      RUBY
    end
  end
end
