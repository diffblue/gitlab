# frozen_string_literal: true

module AwesomeCo
  class << self
    # Seed test data using AwesomeCo generator
    # @param [String] seed_file the full-path of the seed file to load (.yml, .rb)
    def seed(owner, seed_file)
      case File.basename(seed_file)
      when /\.y(a)?ml(\.erb)?/
        Parsers::Yaml.new(seed_file, owner).parse
      end
    end
  end

  class FactoryDefinitions
    attr_reader :name, :group, :definitions, :factory_name

    # @param [String] name Plural name of factory
    # @param [String] group the group that all factories will populate
    # @param [Array<Hash>] definitions Factory definitions
    def initialize(name, group, definitions)
      @name = name
      @group = group
      @definitions = []

      @factory_name = name.singularize

      definitions.each do |definition|
        @definitions << FactoryDefinition.new(factory_name, *definition.delete('traits'), **definition)
      end
    end

    def fabricate_all(parser_binding)
      @definitions.each { |definition| definition.fabricate(parser_binding) }
    end

    def to_s
      @name
    end

    class FactoryDefinition
      attr_reader :id

      # @param [String] factory Singular factory name that matches defined FactoryBot factory
      # @param [Array<String>] traits FactoryBot traits that should be applied
      # @param [Hash<String, String>] attributes Attributes to apply
      def initialize(factory, *traits, **attributes)
        @id = attributes.delete('_id')

        @factory = factory
        @traits = traits
        @attributes = attributes
      end

      def fabricate(parser_binding)
        Gitlab::AppLogger.info("Creating `#{@factory}` with traits `#{@traits}` and attributes `#{@attributes}`")

        build(parser_binding).save
      end

      def build(parser_binding)
        @attributes.transform_values! { |v| v.is_a?(String) ? ERB.new(v).result(parser_binding) : v }

        FactoryBot.build(@factory, *@traits, **@attributes)
      end
    end
  end

  module Parsers
    class Parser
      attr_reader :seed_file,
                  :group,
                  :name,
                  :definitions,
                  :factories

      # @param [String,File] seed_file the File object or Path to file
      # @param [Hash] definitions
      def initialize(seed_file, owner)
        raise 'Please use a Parser subclass' if instance_of?(Parser)

        # read file path instead of file object in case of stream closures
        raise 'Seed file does not exist' unless File.exist?(seed_file.is_a?(String) ? seed_file : seed_file.path)

        @owner = owner
        @factories = []
        @seed_file = File.new(seed_file)
        @parser_binding = binding
      end

      def parse
        # create the seeded group with a path that is hyphenated and random
        @group = FactoryBot.create(:group, name: @name,
                                               path: "#{@name.parameterize}-#{@owner.username}-#{SecureRandom.hex(3)}")
        @group.add_owner(@owner)

        @definitions.each do |factory, definitions|
          @parser_binding.local_variable_set(factory, definitions)

          @factories << FactoryDefinitions.new(factory, group, definitions)
        end

        errors = validate
        raise "There were errors: #{errors}" if errors.any?

        @factories.each { |factory| factory.fabricate_all(@parser_binding) }
      end

      private

      # Ensure the parser format is valid
      # @return [Array<Hash<String, String>>] errors thrown by validation Error: Reason pair
      def validate
        errors = []
        errors << { seed_file: 'must exist' } unless File.exist?(seed_file)
        errors << { seed_file: 'must be of type Hash' } unless @definitions.is_a?(Hash)
        errors << { name: 'must be present' } unless name

        @factories.each do |factory|
          if FactoryBot.factories.registered?(factory.factory_name)
            factory.definitions.each do |definition|
              build = definition.build(@parser_binding)
              errors << build.errors unless build.valid?
            rescue NoMethodError => e
              message = "is not a valid attribute for #{e.receiver}."
              message << " Did you mean #{e.corrections.join(',')}" if e.corrections.any?

              errors << { e.name => message.rstrip }
            rescue KeyError => e
              errors << { e.message => %(for Factory "#{factory.factory_name}") }
            end
          else
            errors << { "#{factory.name}": 'does not refer to a valid registered Factory' }
          end
        end

        errors
      end
    end

    class Yaml < Parser
      require 'yaml'

      def parse
        begin
          @definitions = YAML.safe_load_file(@seed_file, aliases: true)
        rescue Psych::SyntaxError => e
          # put the yaml seed file on the top of the backtrace to help with tracability
          e.backtrace.unshift("#{@seed_file.path}:#{e.line}:#{e.column}")
          raise e, "Seed file is malformed. #{e.message}"
        end
        @name = @definitions.delete('name')

        super
      end
    end
  end
end
