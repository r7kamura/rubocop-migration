# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::ChangeColumn, :config do
  context 'when `change_column` is used' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        change_column :users, :some_column, :new_type
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid changing column type that is in use.
      RUBY
    end
  end

  context 'when `t.change` is used' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        change_table :users do |t|
          t.change :some_column, :new_type
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid changing column type that is in use.
        end
      RUBY
    end
  end
end
