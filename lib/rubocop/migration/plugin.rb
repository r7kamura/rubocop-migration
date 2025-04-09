# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Migration
    class Plugin < ::LintRoller::Plugin
      def about
        ::LintRoller::About.new(
          description: 'RuboCop plugin for ActiveRecord migration.',
          homepage: 'https://github.com/r7kamura/rubocop-migration',
          name: 'rubocop-migration',
          version: VERSION
        )
      end

      def rules(_context)
        ::LintRoller::Rules.new(
          config_format: :rubocop,
          type: :path,
          value: "#{__dir__}/../../../config/default.yml"
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end
    end
  end
end
