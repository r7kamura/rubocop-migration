# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Migration
    # Merge default RuboCop config with plugin config.
    class ConfigLoader
      class << self
        # @param path [String]
        # @return [RuboCop::Config]
        def call(path:)
          new(path: path).call
        end
      end

      # @param path [String]
      def initialize(path:)
        @path = path
      end

      # @return [RuboCop::Config]
      def call
        ::RuboCop::ConfigLoader.merge_with_default(
          plugin_config,
          @path
        )
      end

      private

      # @return [RuboCop::Config]
      def plugin_config
        config = ::RuboCop::Config.new(
          plugin_config_hash,
          @path
        )
        config.make_excludes_absolute
        config
      end

      # @return [Hash]
      def plugin_config_hash
        ::RuboCop::ConfigLoader.send(
          :load_yaml_configuration,
          @path
        )
      end
    end
  end
end
