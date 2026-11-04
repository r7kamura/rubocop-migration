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
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            add_index :users, :name, unique: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY

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
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY

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
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY

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
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            change_table :users do |t|
              t.index :name
              ^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
            end
          end
        end
      RUBY

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

  context 'when `add_index` is used without `:algorithm` option twice' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          def change
            add_index :users, :name1
            ^^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
            add_index :users, :name2
            ^^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            add_index :users, :name1, algorithm: :concurrently
            add_index :users, :name2, algorithm: :concurrently
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used after `create_table` of the same table' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def change
            create_table :users do |t|
              t.string :name
            end
            add_index "users", :name
          end
        end
      RUBY
    end
  end

  context 'when `t.index` is used in `change_table` after `create_table` of the same table' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          def self.up
            create_table :users
            change_table :users do |t|
              t.string :name
              t.index :name
            end
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used after `create_table` of another table' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class CreateArticles < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            create_table :articles
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used after a conditional `create_table` of the same table' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class CreateUsers < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            create_table :users unless table_exists?(:users)
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used after `create_table` of the same table with `if_not_exists: true`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            create_table :users, if_not_exists: true
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY
    end
  end

  context 'when `add_index` is used after `create_table` of the same table in `reversible`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class AddIndexToUsersName < ActiveRecord::Migration[7.0]
          disable_ddl_transaction!

          def change
            reversible do |direction|
              direction.down { create_table :users }
            end
            add_index :users, :name
            ^^^^^^^^^^^^^^^^^^^^^^^ Use `algorithm: :concurrently` on adding indexes to existing tables in PostgreSQL.
          end
        end
      RUBY
    end
  end
end
