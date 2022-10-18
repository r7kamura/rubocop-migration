# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::AddIndexColumnsCount, :config do
  let(:cop_config) do
    { 'MaxColumnsCount' => max_columns_count }
  end

  let(:max_columns_count) do
    3
  end

  context 'when columns count is equal to MaxColumnsCount' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_index :users, %i[a b c]
      RUBY
    end
  end

  context 'when columns count is less than MaxColumnsCount and is 1' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_index :users, :a
      RUBY
    end
  end

  context 'when columns count is greater than MaxColumnsCount on `add_index`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_index :users, %i[a b c d]
                          ^^^^^^^^^^^ Keep unique index columns count less than #{max_columns_count}.
      RUBY
    end
  end

  context 'when columns count is greater than MaxColumnsCount on `t.index`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        create_table :users do |t|
          t.index %i[a b c d]
                  ^^^^^^^^^^^ Keep unique index columns count less than #{max_columns_count}.
        end
      RUBY
    end
  end

  context 'when columns count is greater than customized MaxColumnsCount' do
    let(:max_columns_count) do
      2
    end

    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_index :users, %i[a b c]
                          ^^^^^^^^^ Keep unique index columns count less than #{max_columns_count}.
      RUBY
    end
  end
end
