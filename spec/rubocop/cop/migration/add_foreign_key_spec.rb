# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::AddForeignKey, :config do
  context 'when `add_foreign_key` is used with `validate: false`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_foreign_key :articles, :users, validate: false
      RUBY
    end
  end

  context 'when `add_reference` is used with `foreign_key: false`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_reference :articles, :user, foreign_key: false
      RUBY
    end
  end

  context 'when `add_reference` is used without `:foreign_key` option' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_reference :articles, :user
      RUBY
    end
  end

  context 'when `add_foreign_key` is used without `:validate` option' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_foreign_key :articles, :users
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Activate foreign key validation in a separate migration in PostgreSQL.
      RUBY

      expect_correction(<<~RUBY)
        add_foreign_key :articles, :users, validate: false
      RUBY
    end
  end

  context 'when `add_foreign_key` is used with `validate: true`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_foreign_key :articles, :users, validate: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Activate foreign key validation in a separate migration in PostgreSQL.
      RUBY

      expect_correction(<<~RUBY)
        add_foreign_key :articles, :users, validate: false
      RUBY
    end
  end

  context 'when `add_reference` is used with `foreign_key: true`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_reference :articles, :user, foreign_key: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Activate foreign key validation in a separate migration in PostgreSQL.
      RUBY

      expect_correction(<<~RUBY)
        add_reference :articles, :user
      RUBY
    end
  end
end
