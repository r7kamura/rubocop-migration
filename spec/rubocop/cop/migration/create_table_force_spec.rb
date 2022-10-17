# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::CreateTableForce, :config do
  context 'when `create_table` is used without `:force` option' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        create_table :users
      RUBY
    end
  end

  context 'when `create_table` is used with `force: false` option' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        create_table :users, force: false
      RUBY
    end
  end

  context 'when `create_table` is used with `force: true`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_table :users, force: true
                             ^^^^^^^^^^^ Create tables without `force: true` option.
      TEXT

      expect_correction(<<~RUBY)
        create_table :users
      RUBY
    end
  end
end
