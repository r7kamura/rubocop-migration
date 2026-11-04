# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::AddCheckConstraint, :config do
  context 'when `add_check_constraint` is used with `validate: false`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_check_constraint :orders, 'price > 0', name: 'orders_price_positive', validate: false
      RUBY
    end
  end

  context 'when `add_check_constraint` is used without `:validate` option' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        add_check_constraint :orders, 'price > 0', name: 'orders_price_positive'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Activate a check constraint in a separate migration in PostgreSQL.
      RUBY

      expect_correction(<<~RUBY)
        add_check_constraint :orders, 'price > 0', name: 'orders_price_positive', validate: false
      RUBY
    end
  end

  context 'when `add_check_constraint` is used after `create_table` of the same table' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class CreateOrders < ActiveRecord::Migration[7.0]
          def change
            create_table :orders do |t|
              t.integer :price
            end
            add_check_constraint :orders, "price > 0", name: "orders_price_positive"
          end
        end
      RUBY
    end
  end
end
