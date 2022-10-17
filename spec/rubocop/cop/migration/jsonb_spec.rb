# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::Jsonb, :config do
  context 'when jsonb is used' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_column :users, :properties, :jsonb
      RUBY
    end
  end

  context 'when json is used on `t.json`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_table :users do |t|
          t.json :properties
            ^^^^ Prefer `jsonb` to `json`.
        end
      TEXT

      expect_correction(<<~RUBY)
        create_table :users do |t|
          t.jsonb :properties
        end
      RUBY
    end
  end

  context 'when json is used on `t.change`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        change :users do |t|
          t.change :properties, :json
                                 ^^^^ Prefer `jsonb` to `json`.
        end
      TEXT

      expect_correction(<<~RUBY)
        change :users do |t|
          t.change :properties, :jsonb
        end
      RUBY
    end
  end

  context 'when json is used on `add_column`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        add_column :users, :properties, :json
                                         ^^^^ Prefer `jsonb` to `json`.
      TEXT

      expect_correction(<<~RUBY)
        add_column :users, :properties, :jsonb
      RUBY
    end
  end

  context 'when json is used on `change_column`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        change_column :users, :properties, :json
                                            ^^^^ Prefer `jsonb` to `json`.
      TEXT

      expect_correction(<<~RUBY)
        change_column :users, :properties, :jsonb
      RUBY
    end
  end
end
