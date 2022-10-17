# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::ReservedWordMysql, :config do
  context 'when reserved word is not used as identifier on `add_column`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_column :users, :some_other_good_name, :string
      RUBY
    end
  end

  context 'when reserved word is used as identifier on `add_column`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        add_column :users, :integer, :string
                           ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier at `:name` option on `add_index`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        add_index :foo, :bar, name: :integer
                                    ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier at `:index` option on `add_reference`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        add_reference :foo, :bar, index: { name: :integer }
                                                 ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier `rename_column`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        rename_column :foo, :bar, :integer
                                  ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier `rename_index`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        rename_index :foo, :bar, :integer
                                 ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier `rename_table`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        rename_table :foo, :integer
                           ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier on `create_table`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_table :integer do |t|
                     ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
        end
      TEXT
    end
  end

  context 'when reserved word is used as identifier at `:table_name` option on `create_join_table`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_join_table :foo, :bar, table_name: :integer
                                                  ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
      TEXT
    end
  end

  context 'when reserved word is used as identifier on `t.string`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_table :foo do |t|
          t.string :integer
                   ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
        end
      TEXT
    end
  end

  context 'when reserved word is used as identifier on `t.text`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_table :foo do |t|
          t.text :integer
                 ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
        end
      TEXT
    end
  end

  context 'when reserved word is used as identifier on `t.rename`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        change_table :foo do |t|
          t.rename :bar, :integer
                         ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
        end
      TEXT
    end
  end

  context 'when reserved word is used as identifier at `:index` option on `t.string' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        create_table :foo do |t|
          t.string :bar, index: { name: :integer }
                                        ^^^^^^^^ Avoid using MySQL reserved words as identifiers.
        end
      TEXT
    end
  end
end
