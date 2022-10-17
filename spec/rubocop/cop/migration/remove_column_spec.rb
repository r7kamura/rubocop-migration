# frozen_string_literal: true

require 'pathname'

RSpec.describe RuboCop::Cop::Migration::RemoveColumn, :config do
  before do
    model_pathname.parent.mkpath
    model_pathname.write(model_content)
  end

  after do
    model_pathname.delete
  end

  let(:model_path) do
    'app/models/user.rb'
  end

  let(:model_pathname) do
    Pathname.new(model_path)
  end

  let(:model_content) do
    <<~RUBY
      class User < ApplicationRecord
        self.ignored_columns += %w[some_column]
      end
    RUBY
  end

  context 'when the column is ignored by `self.ignored_columns += %w[...]`' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            remove_column :users, :some_column
          end
        end
      RUBY
    end
  end

  context 'when the column is not ignored by `self.ignored_columns = %w[...]`' do
    let(:model_content) do
      <<~RUBY
        class User < ApplicationRecord
          self.ignored_columns = %w[some_column]
        end
      RUBY
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            remove_column :users, :some_column
          end
        end
      RUBY
    end
  end

  context 'when the column is not ignored by `self.ignored_columns += %i[...]`' do
    let(:model_content) do
      <<~RUBY
        class User < ApplicationRecord
          self.ignored_columns = %i[some_column]
        end
      RUBY
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            remove_column :users, :some_column
          end
        end
      RUBY
    end
  end

  context 'when the column is not included in `ignored_columns`' do
    let(:model_path) do
      'app/models/some_model.rb'
    end

    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class RemoveUsersSomeColumn < ActiveRecord::Migration[7.0]
          def change
            remove_column :users, :some_column
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Make sure the column is already ignored by the running app before removing it.
          end
        end
      RUBY
    end
  end
end
