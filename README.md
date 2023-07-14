# rubocop-migration

[![ci](https://github.com/r7kamura/rubocop-migration/actions/workflows/ci.yml/badge.svg)](https://github.com/r7kamura/rubocop-migration/actions/workflows/ci.yml)

RuboCop extension focused on ActiveRecord migration.

## Usage

Install `rubocop-migration` gem:

```ruby
# Gemfile
gem 'rubocop-migration', require: false
```

then require `rubocop-migration` and enable the cops you want to use in your .rubocop.yml:

```yaml
# .rubocop.yml
require:
  - rubocop-migration

Migration/AddCheckConstraint:
  Enabled: true
```

Note that all cops are `Enabled: false` by default.

## Cops

Please read the comments of the respective cop classes for more information.

- [Migration/AddCheckConstraint](lib/rubocop/cop/migration/add_check_constraint.rb)
- [Migration/AddColumnWithDefaultValue](lib/rubocop/cop/migration/add_column_with_default_value.rb)
- [Migration/AddForeignKey](lib/rubocop/cop/migration/add_foreign_key.rb)
- [Migration/AddIndexColumnsCount](lib/rubocop/cop/migration/add_index_columns_count.rb)
- [Migration/AddIndexConcurrently](lib/rubocop/cop/migration/add_index_concurrently.rb)
- [Migration/AddIndexDuplicate](lib/rubocop/cop/migration/add_index_duplicate.rb)
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

## Acknowledgements

This gem was heavily inspired by [ankane/strong_migrations](https://github.com/ankane/strong_migrations).

The gem `rubocop-migration` was originally developed at [wealthsimple/rubocop-migration](https://github.com/wealthsimple/rubocop-migration), and later the gem name was transferred to this repository.

Some cops were originally created at [r7kamura/sevencop](https://github.com/r7kamura/sevencop) then moved to this repository.
