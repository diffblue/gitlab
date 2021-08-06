# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Bridge do
  subject { described_class.new(config, name: :my_bridge) }

  describe '.matching?' do
    subject { described_class.matching?(name, config) }

    context 'when config is a bridge job' do
      let(:name) { :my_trigger }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '.new' do
    before do
      subject.compose!
    end

    let(:base_config) do
      {
        trigger: { project: 'some/project', branch: 'feature' },
        needs: { pipeline: 'other/project' },
        extends: '.some-key',
        stage: 'deploy',
        variables: { VARIABLE: '123' }
      }
    end

    context 'when needs pipeline config is a non-empty string' do
      let(:config) { { needs: { pipeline: 'some/project' } } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(name: :my_bridge,
                                      needs: { bridge: [{ pipeline: 'some/project' }] },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] },
                                      job_variables: {},
                                      root_variables_inheritance: true,
                                      scheduling_type: :stage)
        end
      end
    end

    context 'when needs config is a job' do
      let(:config) { { trigger: { project: 'some/project' }, needs: ['some_job'] } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(name: :my_bridge,
                                      trigger: { project: 'some/project' },
                                      needs: { job: [{ name: 'some_job', artifacts: true, optional: false }] },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] },
                                      job_variables: {},
                                      root_variables_inheritance: true,
                                      scheduling_type: :dag)
        end
      end
    end

    context 'when bridge configuration contains trigger, needs, when, extends, stage, only, except, and variables' do
      let(:config) do
        base_config.merge({
          when: 'always',
          only: { variables: %w[$SOMEVARIABLE] },
          except: { refs: %w[feature] }
        })
      end

      it { is_expected.to be_valid }
    end

    context 'when trigger config is nil' do
      let(:config) { { trigger: nil } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about empty trigger config' do
          expect(subject.errors.first).to eq('bridge config should contain either a trigger or a needs:pipeline')
        end
      end
    end

    context 'when upstream config is nil' do
      let(:config) { { needs: nil } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about empty upstream config' do
          expect(subject.errors.first).to eq('bridge config should contain either a trigger or a needs:pipeline')
        end
      end
    end

    context 'when bridge has bridge and job needs' do
      let(:config) do
        {
          trigger: 'other-project',
          needs: ['some_job', { pipeline: 'some/other_project' }]
        }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end
    end

    context 'when bridge has bridge and cross projects dependencies ' do
      let(:config) do
        {
          trigger: 'other-project',
          needs: [
            { pipeline: 'some/other_project' },
            {
              project: 'some/project',
              job: 'some/job',
              ref: 'some/ref',
              artifacts: true
            }
          ]
        }
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error cross dependencies' do
          expect(subject.errors).to contain_exactly('needs config uses invalid types: cross_dependency')
        end
      end
    end

    context 'when bridge has more than one valid bridge needs' do
      let(:config) do
        {
          trigger: 'other-project',
          needs: [{ pipeline: 'some/project' }, { pipeline: 'some/other_project' }]
        }
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error about too many bridge needs' do
          expect(subject.errors).to contain_exactly('bridge config should contain at most one bridge need')
        end
      end
    end
  end
end
