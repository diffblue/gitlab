# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Need do
  subject(:need) { described_class.new(config) }

  context 'with Bridge config' do
    context 'when upstream is specified' do
      let(:config) { { pipeline: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(subject.value).to eq(pipeline: 'some/project')
        end
      end
    end

    context 'when need is empty' do
      let(:config) { {} }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about an empty config' do
          expect(subject.errors)
            .to include("bridge hash config can't be blank")
        end
      end
    end
  end

  context 'with CrossProjectDependency config' do
    describe '#artifacts' do
      using RSpec::Parameterized::TableSyntax

      where(:artifacts,      :value, :validity) do
        { artifacts: true }  | true  | true
        { artifacts: false } | false | true
        { artifacts: nil }   | true  | true
        {}                   | true  | true
        { artifacts: 1 }     | 1     | false
        { artifacts: 'str' } | 'str' | false
      end

      with_them do
        let(:config) do
          {
            project: 'some/project',
            job: 'some/job',
            ref: 'some/ref'
          }.merge(artifacts)
        end

        describe '#valid?' do
          it { expect(subject.valid?).to eq(validity) }
        end

        describe '#value' do
          it 'returns job needs configuration' do
            expect(subject.value)
              .to eq(artifacts: value, job: 'some/job', project: 'some/project', ref: 'some/ref')
          end
        end

        describe '#type' do
          it { expect(subject.type).to eq(:cross_dependency) }
        end
      end
    end

    shared_examples 'required string attribute' do |attribute|
      describe "##{attribute}" do
        using RSpec::Parameterized::TableSyntax

        let(:general_config) do
          {
            job: 'some/job',
            ref: 'some/ref',
            project: 'some/project',
            artifacts: true
          }.tap { |config| config.delete(attribute) }
        end

        where(:value, :validity, :error) do
          {}                           | false | "can't be blank"
          { attribute => nil }         | false | "can't be blank"
          { attribute => 'something' } | true  | ''
          { attribute => :symbol }     | false | 'should be a string'
          { attribute => 1 }           | false | 'should be a string'
        end

        with_them do
          let(:config) { general_config.merge(value).freeze }

          describe '#valid?' do
            it { expect(subject.valid?).to eq(validity) }
          end

          describe '#value' do
            it 'returns needs configuration' do
              expect(subject.value).to eq(config)
            end
          end

          describe '#type' do
            it { expect(subject.type).to eq(:cross_dependency) }
          end

          describe '#errors' do
            subject(:errors) { need.errors }

            let(:error_message) { "cross project dependency #{attribute} #{error}" }

            it { is_expected.to(be_empty)               if validity }
            it { is_expected.to(include(error_message)) unless validity }
          end
        end
      end
    end

    it_behaves_like 'required string attribute', :project
    it_behaves_like 'required string attribute', :job
    it_behaves_like 'required string attribute', :ref
  end
end
