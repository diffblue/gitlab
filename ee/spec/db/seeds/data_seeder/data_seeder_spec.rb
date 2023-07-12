# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../db/seeds/data_seeder/data_seeder'

module Gitlab
  RSpec.describe DataSeeder, feature_category: :scalability do
    let(:seed_file_name) { 'data_seeder' }
    let(:seed_file_content) do
      'Content'
    end

    let!(:seed_file) do
      Tempfile.open(seed_file_name) do |f|
        f.write(seed_file_content)
        f
      end
    end

    let(:owner) { create(:user) }
    let(:group) { create(:group) }

    let(:factory_attributes) do
      { name: 'AwesomeCo Label', group: group, color: '#FF0000' }
    end

    describe '.seed' do
      let(:owner) { create(:user) }

      subject(:seed) { described_class.seed(owner, seed_file) }

      context 'when seed file is a yaml file' do
        let(:seed_file_name) { 'data_seeder.yml' }
        let(:seed_file_content) do
          <<~YAML
            ---
            name: Test
            issues:
              - title: Test
          YAML
        end

        shared_examples 'parses the file' do |klass|
          it "parses with #{klass}" do
            expect_next_instance_of(klass) do |instance|
              expect(instance).to receive(:parse)
            end
            seed
          end
        end

        context 'with .yml extension' do
          it_behaves_like 'parses the file', DataSeeder::Parsers::Yaml
        end

        context 'with .yml.erb extension' do
          let(:seed_file_name) { 'data_seeder.yml.erb' }

          it_behaves_like 'parses the file', DataSeeder::Parsers::Yaml
        end

        context 'with .json.erb extension' do
          let(:seed_file_name) { 'data_seeder.json.erb' }

          it_behaves_like 'parses the file', DataSeeder::Parsers::Json
        end

        context 'with .json extension' do
          let(:seed_file_name) { 'data_seeder.json' }

          it_behaves_like 'parses the file', DataSeeder::Parsers::Json
        end

        context 'when seed file is invalid yaml' do
          let(:seed_file_content) do
            <<~YAML
              ---
              # invalid yaml
              this is invalid yaml
              file: yes
            YAML
          end

          it 'raises an error' do
            expect { seed }.to raise_error(Psych::SyntaxError, /Seed file is malformed/)
          end

          it 'error backtrace contains the seed file' do
            expect { seed }.to raise_error do |error|
              expect(error.backtrace.first).to include(seed_file_name)
            end
          end
        end
      end
    end

    describe DataSeeder::FactoryDefinitions do
      subject(:factory_definitions) { described_class.new('group_labels', group, [factory_attributes]) }

      describe '#to_s' do
        it 'returns the name' do
          expect(factory_definitions.to_s).to eq('group_labels')
        end
      end

      describe '#definitions' do
        let(:definitions) { factory_definitions.definitions }

        it 'returns exactly one well-formed definition', :aggregate_failures do
          expect(definitions.size).to eq(1)
          expect(definitions.first).to be_a(DataSeeder::FactoryDefinitions::FactoryDefinition)
        end
      end

      describe '#fabricate_all' do
        it 'fabricates a group label' do
          expect { factory_definitions.fabricate_all(binding) }.to change { GroupLabel.count }.by(1)
        end
      end

      describe '#factory_name' do
        it 'singularizes the factory name' do
          expect(factory_definitions.factory_name).to eq('group_label')
        end
      end

      describe DataSeeder::FactoryDefinitions::FactoryDefinition do
        subject(:definition) { described_class.new('group_label', nil, **factory_attributes) }

        describe '#fabricate' do
          it 'saves the built record' do
            expect { definition.fabricate(binding) }.to change { GroupLabel.count }.by(1)
          end
        end

        describe '#build' do
          context 'when value is a simple string' do
            let(:factory_attributes) do
              { name: 'AwesomeCo Label', group_id: '2', color: '#FF0000' }
            end

            it 'sets the value' do
              expect(definition.build(binding).group_id).to eq(2)
            end
          end

          context 'when erb is included as a value' do
            let(:factory_attributes) do
              { name: 'AwesomeCo Label', group_id: '<%= 1 + 1 %>', color: '#FF0000' }
            end

            it 'embeds Ruby' do
              expect(definition.build(binding).group_id).to eq(2)
            end
          end

          it 'builds a model' do
            expect(definition.build(binding)).to be_a(GroupLabel)
          end
        end
      end
    end

    describe 'Parsers' do
      let(:namespace) { create(:namespace) }

      after do
        seed_file.unlink
      end

      subject(:parser) { described_class.new(seed_file, owner) }

      describe DataSeeder::Parsers::Parser do
        describe '#initialize' do
          it 'raises an error if trying to initialize Parser without a subclass' do
            expect { parser }.to raise_error(RuntimeError, /Parser subclass/)
          end
        end

        context 'with a seed file that does not exist' do
          subject(:parser) do
            Class.new(described_class) do
              def initialize(_seed_file, owner)
                super('invalid', owner)
              end
            end
          end

          it 'raises an error' do
            expect { parser.new('invalid', owner) }.to raise_error(RuntimeError, /Seed file does not exist/)
          end
        end
      end

      describe DataSeeder::Parsers::Yaml do
        let(:seed_file_name) { 'data_seeder.yml' }
        let(:seed_file_content) do
          <<~YAML
            ---
            name: Test
            group_labels:
              - name: Group Label
                traits:
                  - described

            projects:
              - name: Test Project
                traits:
                  - public
          YAML
        end

        describe 'validation' do
          context 'when seed file is invalid' do
            it_behaves_like 'raises an error when specifying an invalid factory' do
              let(:seed_file_content) do
                <<~YAML
                  ---
                  name: Invalid

                  invalids:
                    - name: Test
                YAML
              end
            end

            it_behaves_like 'specifying invalid traits to a factory' do
              let(:seed_file_content) do
                <<~YAML
                  ---
                  name: Test
                  issues:
                    - title: Test
                      traits:
                        - invalid
                YAML
              end
            end

            it_behaves_like 'specifying invalid attributes to a factory' do
              let(:seed_file_content) do
                <<~YAML
                  ---
                  name: Invalid Attributes
                  issues:
                    - mileston: true
                YAML
              end
            end
          end

          it_behaves_like 'an id already exists' do
            let(:seed_file_content) do
              <<~YAML
                name: Test
                group_labels:
                  - _id: my_label
                    title: My Label
                  - _id: my_label
                    title: My other label
              YAML
            end
          end
        end

        describe '#parse' do
          it_behaves_like 'name is not specified' do
            let(:seed_file_content) do
              <<~YAML
                group_labels:
                  - title: My Label
              YAML
            end
          end
        end

        context 'when parsed' do
          it_behaves_like 'has a name'
          it_behaves_like 'factory definitions'
          it_behaves_like 'passes traits' do
            let(:seed_file_content) do
              <<~YAML
                ---
                name: Test
                group_labels:
                  - title: Test Label
                    traits:
                      - described
              YAML
            end
          end

          describe '@parser_binding' do
            let(:group_labels) { parser.instance_variable_get(:@parser_binding).local_variable_get('group_labels') }

            context 'when a definition has an id' do
              let(:seed_file_content) do
                <<~YAML
                  name: Test
                  group_labels:
                    - _id: my_label
                      title: My Label
                YAML
              end

              it_behaves_like 'definition has an id'
              it_behaves_like 'id has spaces' do
                let(:seed_file_content) do
                  <<~YAML
                    name: Test
                    group_labels:
                      - _id: id with spaces
                        title: With Spaces
                  YAML
                end
              end

              context 'when id is malformed' do
                context 'when id contains invalid characters' do
                  it_behaves_like 'invalid id', /id `--invalid-id` is invalid/ do
                    let(:seed_file_content) do
                      <<~YAML
                        name: Test
                        group_labels:
                          - _id: --invalid-id
                      YAML
                    end
                  end

                  it_behaves_like 'invalid id', /id `invalid!id` is invalid/ do
                    let(:seed_file_content) do
                      <<~YAML
                        name: Test
                        group_labels:
                          - _id: invalid!id
                      YAML
                    end
                  end

                  it_behaves_like 'invalid id', /id `1_label` is invalid. id cannot start with a number/ do
                    let(:seed_file_content) do
                      <<~YAML
                        name: Test
                        group_labels:
                          - _id: 1_label
                      YAML
                    end
                  end
                end
              end
            end

            it_behaves_like 'definition does not have an id' do
              let(:seed_file_content) do
                <<~YAML
                  name: Test
                  group_labels:
                    - title: Test
                YAML
              end
            end
          end
        end
      end

      describe DataSeeder::Parsers::Json do
        let(:seed_file_name) { 'seeder.json' }
        let(:seed_file_content) do
          {
            name: 'Test',
            group_labels: [
              { name: 'Group Label', traits: %w[described] }
            ],
            projects: [
              { name: 'Test Project', traits: %w[public] }
            ]
          }.to_json
        end

        describe 'validation' do
          context 'when seed file is invalid' do
            it_behaves_like 'raises an error when specifying an invalid factory' do
              let(:seed_file_content) do
                {
                  name: 'Invalid seed',
                  invalids: [
                    { name: 'Test' }
                  ]
                }.to_json
              end
            end

            it_behaves_like 'specifying invalid traits to a factory' do
              let(:seed_file_content) do
                {
                  name: 'Test',
                  issues: [
                    { title: 'Test', traits: %w[invalid] }
                  ]
                }.to_json
              end
            end

            it_behaves_like 'specifying invalid attributes to a factory' do
              let(:seed_file_content) do
                {
                  name: 'Invalid Attributes',
                  issues: [
                    { mileston: true }
                  ]
                }.to_json
              end
            end
          end

          it_behaves_like 'an id already exists' do
            let(:seed_file_content) do
              {
                name: 'Test',
                group_labels: [
                  { _id: 'my_label', name: 'My Label' },
                  { _id: 'my_label', name: 'My Other Label' }
                ]
              }.to_json
            end
          end
        end

        describe '#parse' do
          it_behaves_like 'name is not specified' do
            let(:seed_file_content) do
              {
                group_labels: [
                  { title: 'My Label' }
                ]
              }.to_json
            end
          end

          context 'when parsed' do
            it_behaves_like 'has a name'
            it_behaves_like 'factory definitions'
            it_behaves_like 'passes traits' do
              let(:seed_file_content) do
                {
                  name: 'Test',
                  group_labels: [
                    { title: 'Test Label', traits: %w[described] }
                  ]
                }.to_json
              end

              describe '@parser_binding' do
                let(:group_labels) { parser.instance_variable_get(:@parser_binding).local_variable_get('group_labels') }

                context 'when id is malformed' do
                  context 'when id contains invalid characters' do
                    it_behaves_like 'invalid id', /id `--invalid-id` is invalid/ do
                      let(:seed_file_content) do
                        {
                          name: 'Test',
                          group_labels: [
                            { _id: '--invalid-id' }
                          ]
                        }.to_json
                      end
                    end

                    it_behaves_like 'invalid id', /id `invalid!id` is invalid/ do
                      let(:seed_file_content) do
                        {
                          name: 'Test',
                          group_labels: [
                            { _id: 'invalid!id' }
                          ]
                        }.to_json
                      end
                    end

                    it_behaves_like 'invalid id', /id `1_label` is invalid. id cannot start with a number/ do
                      let(:seed_file_content) do
                        {
                          name: 'Test',
                          group_labels: [
                            { _id: '1_label' }
                          ]
                        }.to_json
                      end
                    end
                  end

                  it_behaves_like 'definition does not have an id' do
                    let(:seed_file_content) do
                      {
                        name: 'Test',
                        group_labels: [
                          { title: 'Test' }
                        ]
                      }.to_json
                    end
                  end
                end
              end
            end
          end
        end
      end

      describe DataSeeder::Parsers::Ruby do
        let(:seed_file_name) { 'awesome.rb' }
        let(:seed_file_content) do
          <<~RUBY
            class DataSeeder
              def seed
                create(:group_label, name: 'Test Group', group: @group, color: '#FF0000')
              end
            end
          RUBY
        end

        it 'parses and creates a group label' do
          expect { parser.parse }.to change { GroupLabel.count }.by(1)
        end

        context 'with instance variables' do
          let(:seed_file_content) do
            <<~RUBY
              class DataSeeder
                def seed
                  puts @seed_file.path
                  puts @owner.name
                  puts @name == nil
                  puts @group.name
                end
              end
            RUBY
          end

          it 'can refer to instance variables' do
            expect { parser.parse }.to output(/#{seed_file.path}/).to_stdout
            expect { parser.parse }.to output(/#{owner.name}/).to_stdout
            expect { parser.parse }.to output(/false/).to_stdout
            expect { parser.parse }.to output(/#{File.basename(seed_file)}/).to_stdout
          end
        end

        context 'when the ruby is invalid' do
          context 'with a syntax error' do
            let(:seed_file_content) do
              <<~RUBY
                class DataSeeder
                  def seed
                    create(:group, name: 'Test Group', 'my-group-path')
                  end
                end
              RUBY
            end

            it 'throws an error' do
              expect { parser.parse }.to raise_error(SyntaxError)
            end
          end

          context 'with a database uniqueness constraint' do
            let(:seed_file_content) do
              <<~RUBY
                class DataSeeder
                  def seed
                    create(:group, id: 99, name: 'Test Group', path: 'my-group-path')
                    create(:group, id: 99, name: 'Test Group', path: 'my-group-path')
                  end
                end
              RUBY
            end

            it 'throws an error' do
              expect { parser.parse }.to raise_error(ActiveRecord::RecordNotUnique)
            end
          end
        end
      end
    end
  end
end
