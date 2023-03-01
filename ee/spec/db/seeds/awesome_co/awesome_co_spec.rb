# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../db/seeds/awesome_co/awesome_co'

module AwesomeCo
  RSpec.describe AwesomeCo, feature_category: :scalability do
    let(:seed_file_name) { 'awesome_co' }
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
        let(:seed_file_name) { 'awesome_co.yml' }
        let(:seed_file_content) do
          <<~YAML
            ---
            name: Test
            issues:
              - title: Test
          YAML
        end

        shared_examples 'parses the yaml' do
          it 'parses the yaml' do
            expect_next_instance_of(AwesomeCo::Parsers::Yaml) do |instance|
              expect(instance).to receive(:parse)
            end
            seed
          end
        end

        context 'with .yml extension' do
          it_behaves_like 'parses the yaml'
        end

        context 'with .yml.erb extension' do
          let(:seed_file_name) { 'awesome_co.yml.erb' }

          it_behaves_like 'parses the yaml'
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

    describe FactoryDefinitions do
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
          expect(definitions.first).to be_a(FactoryDefinitions::FactoryDefinition)
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

      describe FactoryDefinitions::FactoryDefinition do
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

      describe Parsers::Parser do
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

      describe Parsers::Yaml do
        let(:seed_file_name) { 'awesome_co.yml' }
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
            context 'when specifying an invalid factory' do
              let(:seed_file_content) do
                <<~YAML
                  ---
                  name: Invalid

                  invalids:
                    - name: Test
                YAML
              end

              it 'raises an error' do
                expect { parser.parse }.to raise_error(RuntimeError, /invalids.*to a valid registered Factory/)
              end
            end

            context 'when specifying invalid traits to a factory' do
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

              it 'raises an error', :aggregate_failures do
                expect { parser.parse }.to raise_error do |error|
                  expect(error).to be_a(RuntimeError)
                  expect(error.message).to include('Trait not registered: \\"invalid\\"')
                  expect(error.message).to include('for Factory \\"issue\\"')
                end
              end
            end

            context 'when specifying invalid attributes to a factory' do
              let(:seed_file_content) do
                <<~YAML
                  ---
                  name: Invalid Attributes
                  issues:
                    - invalid: true
                YAML
              end

              it 'raises an error' do
                expect { parser.parse }.to raise_error(RuntimeError, /is not a valid attribute/)
              end

              it 'contains possible alternatives' do
                expect { parser.parse }.to raise_error(RuntimeError, /Did you mean/)
              end
            end
          end
        end

        context 'when parsed' do
          it 'has a name' do
            parser.parse

            expect(parser.name).to eq('Test')
          end

          describe 'factory definitions' do
            it 'has exactly two definitions' do
              parser.parse

              expect(parser.definitions.size).to eq(2)
            end

            it 'creates the group label' do
              expect { parser.parse }.to change { GroupLabel.count }.by(1)
            end

            it 'creates the project' do
              expect { parser.parse }.to change { Project.count }.by(1)
            end
          end

          context 'when passing traits' do
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

            it 'passes traits' do
              expect_next_instance_of(AwesomeCo::FactoryDefinitions::FactoryDefinition) do |instance|
                # `described` trait will automaticaly generate a description
                expect(instance.build(binding).description).to eq('Description of Test Label')
              end

              parser.parse
            end
          end
        end
      end
    end
  end
end
