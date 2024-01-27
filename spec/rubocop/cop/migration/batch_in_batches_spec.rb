# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::BatchInBatches, :config do
  context 'when `update_all` is used with block `in_batches`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.in_batches do |relation|
              relation.update_all(some_column: 'some value')
            end
          end
        end
      RUBY
    end
  end

  context 'when `update_all` is used with inline `in_batches`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.in_batches.update_all(some_column: 'some value')
          end
        end
      RUBY
    end
  end

  context 'when `update_all` is used not with block `in_batches`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.update_all(some_column: 'some value')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `in_batches` in batch processing.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.in_batches do |relation|
          relation.update_all(some_column: 'some value')
        end
          end
        end
      RUBY
    end
  end

  context 'when `delete_all` is used without `sleep`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.delete_all
            ^^^^^^^^^^^^^^^ Use `in_batches` in batch processing.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.in_batches do |relation|
          relation.delete_all
        end
          end
        end
      RUBY
    end
  end
end
