# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::BatchWithThrottling, :config do
  context 'when `update_all` is used with `sleep`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            User.in_batches do |relation|
              relation.update_all(some_column: 'some value')
              sleep(0.01)
            end
          end
        end
      RUBY
    end
  end

  context 'when `update_all` is used without `sleep` not in block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            User.update_all(some_column: 'some value')
          end
        end
      RUBY
    end
  end

  context 'when `update_all` is used without `sleep`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            User.in_batches do |relation|
              relation.update_all(some_column: 'some value')
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use throttling in batch processing.
            end
          end
        end
      TEXT

      expect_correction(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            User.in_batches do |relation|
              relation.update_all(some_column: 'some value')
              sleep(0.01)
            end
          end
        end
      TEXT
    end
  end

  context 'when `delete_all` is used without `sleep`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            User.in_batches do |relation|
              relation.delete_all
              ^^^^^^^^^^^^^^^^^^^ Use throttling in batch processing.
            end
          end
        end
      TEXT

      expect_correction(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            User.in_batches do |relation|
              relation.delete_all
              sleep(0.01)
            end
          end
        end
      TEXT
    end
  end
end
