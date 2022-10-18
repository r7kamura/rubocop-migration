# frozen_string_literal: true

require 'pathname'

RSpec.describe RuboCop::Cop::Migration::AddIndexDuplicate, :config do
  before do
    db_schema_pathname.parent.mkpath
    db_schema_pathname.write(db_schema_content)
  end

  after do
    db_schema_pathname.delete
  end

  let(:db_schema_content) do
    <<~RUBY
      ActiveRecord::Schema.define(version: 2000_01_01_000000) do
        create_table "users", force: :cascade do |t|
          t.string "email", null: false
          t.string "name", null: false
          t.index ["name", "email"], name: "index_users_on_name_and_email"
        end
      end
    RUBY
  end

  let(:db_schema_path) do
    'db/schema.rb'
  end

  let(:db_schema_pathname) do
    Pathname.new(db_schema_path)
  end

  context 'when non-duplicate index is added' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_index :users, :email

        add_index :users, %i[name email foo]

        change_table :users do |t|
          t.index :email
        end
      RUBY
    end
  end

  context 'when db/schema.rb is not found' do
    let(:db_schema_path) do
      'not_found.rb'
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_index :users, :email
      RUBY
    end
  end

  context 'when duplicate index is added by `add_index`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_index :users, :name
        ^^^^^^^^^^^^^^^^^^^^^^^ Avoid adding duplicate indexes.
      RUBY
    end
  end

  context 'when duplicate index is added by `t.index`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        change_table :users do |t|
          t.index :name
          ^^^^^^^^^^^^^ Avoid adding duplicate indexes.
        end
      RUBY
    end
  end
end
