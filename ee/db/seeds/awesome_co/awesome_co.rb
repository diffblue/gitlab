# frozen_string_literal: true

require 'ostruct'

module AwesomeCo
  class << self
    # Seed test data using AwesomeCo generator
    # @param [String] seed_file the full-path of the seed file to load (.yml, .rb)
    def seed(owner, seed_file)
      case File.basename(seed_file)
      when /\.y(a)?ml(\.erb)?/
        Parsers::Yaml.new(seed_file, owner).parse
      when /\.json(\.erb)?/
        Parsers::Json.new(seed_file, owner).parse
      when /\.rb/
        Parsers::Ruby.new(seed_file, owner).parse
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
        # "my id" #=> "my_id"
        # "my_id" #=> "my_id"
        @id = attributes.delete('_id')

        if @id
          raise "id `#{@id}` is invalid" if @id.match?(/[\x21-\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\x7F]/) # special chars
          raise "id `#{@id}` is invalid. id cannot start with a number" if @id.match?(/^[0-9]/)

          if @id.include?(' ')
            new_id = @id.tr(' ', '_')
            warn %(parsing id "#{@id}" as "#{new_id}")

            @id = new_id
          end
        end

        @factory = factory
        @traits = traits
        @attributes = attributes
      end

      # Build and save the Factory
      # @param [Binding] parser_binding
      # @return [ApplicationRecord] the built and saved Factory
      def fabricate(parser_binding)
        factory = if @id
                    parser_binding.local_variable_get(@factory.pluralize)[@id]
                  else
                    build(parser_binding)
                  end

        factory.tap do |f|
          f.save
          Gitlab::AppLogger.info(
            "Created `#{@factory}` with traits `#{@traits}` and attributes `#{@attributes}` [ID: #{f.id}]"
          )

          parser_binding.local_variable_get(@factory.pluralize)[@id] = f if @id
        end
      end

      # Build the Factory
      # @param [Binding] parser_binding
      # @return [ApplicationRecord] the built factory
      def build(parser_binding)
        @attributes.transform_values! { |v| v.is_a?(String) ? ERB.new(v).result(parser_binding) : v }

        FactoryBot.build(@factory, *@traits, **@attributes).tap do |factory|
          next unless @id
          next unless parser_binding.local_variable_defined?(@factory.pluralize)

          raise "id `#{@id}` must be unique" if parser_binding.local_variable_get(@factory.pluralize)[@id]

          parser_binding.local_variable_get(@factory.pluralize)[@id] = factory if @id
        end
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
        raise 'Seed file must specify a name' unless @name

        # create the seeded group with a path that is hyphenated and random
        @group = FactoryBot.create(:group, name: @name,
                                               path: "#{@name.parameterize}-#{@owner.username}-#{SecureRandom.hex(3)}")
        @group.add_owner(@owner)

        @definitions.each do |factory, definitions|
          # Using OpenStruct for dot-notation and saves a custom class impl. Ruby's discouragement does not apply
          @parser_binding.local_variable_set(factory, OpenStruct.new) unless @parser_binding.local_variable_defined?(factory) # rubocop:disable Style/OpenStructUse

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
              message = +"is not a valid attribute for #{e.receiver}."
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
          # put the yaml seed file on the top of the backtrace to help with traceability
          e.backtrace.unshift("#{@seed_file.path}:#{e.line}:#{e.column}")
          raise e, "Seed file is malformed. #{e.message}"
        end
        @name = @definitions.delete('name')

        super
      end
    end

    class Json < Parser
      require 'json'

      def parse
        @definitions = JSON.load_file(@seed_file)
        @name = @definitions.delete('name')

        super
      end
    end

    class Ruby < Parser
      def initialize(seed_file, owner)
        @seed_file = seed_file
        @owner = owner
        @name = File.basename(@seed_file, '.rb')

        # create the seeded group with a path that is hyphenated and random
        @group = FactoryBot.create(:group, name: @name,
                                          path: "#{@name.parameterize}-#{@owner.username}-#{SecureRandom.hex(3)}")
        @group.add_owner(@owner)
      end

      def parse
        load @seed_file

        DataSeeder.include(FactoryBot::Syntax::Methods) unless DataSeeder.include?(FactoryBot::Syntax::Methods)

        DataSeeder.new.tap do |seeder|
          seeder.instance_variable_set(:@seed_file, @seed_file)
          seeder.instance_variable_set(:@owner, @owner)
          seeder.instance_variable_set(:@name, @name)
          seeder.instance_variable_set(:@group, @group)

          seeder.seed
        end
      end
    end
  end
end
