# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::AddIndexConcurrently, :config do
  context 'when `add_index` is used with `algorithm: :concurrently' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        add_index :users, :name, algorithm: :concurrently
      RUBY
    end
  end

  context 'when `t.index` is used in `create_table`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        create_table :users do |t|
          t.index :name
        end
      RUBY
    end
  end

  context 'when `add_index` is used with some options' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            add_index :users, :name, unique: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      TEXT

      expect_correction(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            add_index :users, :name, unique: true, algorithm: :concurrently
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used without `:algorithm` option' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      TEXT

      expect_correction(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            add_index :users, :name, algorithm: :concurrently
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used without `:algorithm` option where `disable_ddl_transaction!` is already used' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      TEXT

      expect_correction(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            add_index :users, :name, algorithm: :concurrently
          end
        end
      RUBY
    end
  end

  context 'when `t.index` is used without `:algorithm` option in `change_table`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            change_table :users do |t|
              t.index :name
              ^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
            end
          end
        end
      TEXT

      expect_correction(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            change_table :users do |t|
              t.index :name, algorithm: :concurrently
            end
          end
        end
      RUBY
    end
  end
end
