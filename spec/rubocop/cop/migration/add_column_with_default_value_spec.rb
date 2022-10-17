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
      expect_offense(<<~TEXT)
        add_column :users, :some_column, :string, default: 'some value'
                                                  ^^^^^^^^^^^^^^^^^^^^^ Add the column without a default value then change the default.
      TEXT

      expect_correction(<<~RUBY)
        add_column :users, :some_column, :string
        change_column_default :users, :some_column, 'some value'
      RUBY
    end
  end

  context 'when `t.string` is used with non-nil `:default` option in `change_table`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        change_table :users do |t|
          t.string :some_column, default: 'some value'
                                 ^^^^^^^^^^^^^^^^^^^^^ Add the column without a default value then change the default.
        end
      TEXT

      expect_correction(<<~RUBY)
        change_table :users do |t|
          t.string :some_column
        end
        change_column_default :users, :some_column, 'some value'
      RUBY
    end
  end
end
