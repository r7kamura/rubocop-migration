# rubocop-migration

RuboCop extension focused on ActiveRecord migration.

## Usage

Install `rubocop-migration` gem:

```ruby
# Gemfile
gem 'rubocop-migration', require: false
```

then require `rubocop-migration` in your .rubocop.yml:

```yaml
# .rubocop.yml
require:
  - rubocop-migration
```

## Cops

- [Migration/AddCheckConstraint](lib/rubocop/cop/migration/add_check_constraint.rb)
- [Migration/AddColumnWithDefaultValue](lib/rubocop/cop/migration/add_column_with_default_value.rb)
- [Migration/AddForeignKey](lib/rubocop/cop/migration/add_foreign_key.rb)
- [Migration/AddIndexConcurrently](lib/rubocop/cop/migration/add_index_concurrently.rb)
- [Migration/BatchInBatches](lib/rubocop/cop/migration/batch_in_batches.rb)
- [Migration/BatchInTransaction](lib/rubocop/cop/migration/batch_in_transaction.rb)
- [Migration/BatchWithThrottling](lib/rubocop/cop/migration/batch_with_throttling.rb)
- [Migration/ChangeColumn](lib/rubocop/cop/migration/change_column.rb)
- [Migration/ChangeColumnNull](lib/rubocop/cop/migration/change_column_null.rb)
- [Migration/CreateTableForce](lib/rubocop/cop/migration/create_table_force.rb)
- [Migration/Jsonb](lib/rubocop/cop/migration/jsonb.rb)
- [Migration/RemoveColumn](lib/rubocop/cop/migration/remove_column.rb)
- [Migration/RenameColumn](lib/rubocop/cop/migration/rename_column.rb)
- [Migration/RenameTable](lib/rubocop/cop/migration/rename_table.rb)
- [Migration/ReservedWordMysql](lib/rubocop/cop/migration/reserved_word_mysql.rb)
- [Migration/UniqueIndexColumnsCount](lib/rubocop/cop/migration/unique_index_columns_count.rb)

## Acknowledgements

This gem was heavily inspired by the following gem:

- [ankane/strong_migrations](https://github.com/ankane/strong_migrations)
