# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Migration::BatchInBatches, :config do
  context 'when `update_all` is used within `in_batches`' do
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

  context 'when `update_all` is used not within `in_batches`' do
    it 'registers an offense' do
      expect_offense(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.update_all(some_column: 'some value')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `in_batches` in batch processing.
          end
        end
      TEXT

      expect_correction(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.in_batches do |relation|
          relation.update_all(some_column: 'some value')
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
          def change
            User.delete_all
            ^^^^^^^^^^^^^^^ Use `in_batches` in batch processing.
          end
        end
      TEXT

      expect_correction(<<~TEXT)
        class BackfillUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            User.in_batches do |relation|
          relation.delete_all
        end
          end
        end
      TEXT
    end
  end
end
