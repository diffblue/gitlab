# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::YamlProcessor do
  describe 'Bridge Needs' do
    let(:config) do
      {
        build: { stage: 'build', script: 'test' },
        bridge: { stage: 'test', needs: needs }
      }
    end

    subject { described_class.new(YAML.dump(config)).execute }

    context 'needs upstream pipeline' do
      let(:needs) { { pipeline: 'some/project' } }

      it 'creates jobs with valid specification' do
        expect(subject.builds.size).to eq(2)
        expect(subject.builds[0]).to eq(
          stage: "build",
          stage_idx: 1,
          name: "build",
          only: { refs: %w[branches tags] },
          options: {
            script: ["test"]
          },
          when: "on_success",
          allow_failure: false,
          job_variables: [],
          root_variables_inheritance: true,
          scheduling_type: :stage
        )
        expect(subject.builds[1]).to eq(
          stage: "test",
          stage_idx: 2,
          name: "bridge",
          only: { refs: %w[branches tags] },
          options: {
            bridge_needs: { pipeline: 'some/project' }
          },
          when: "on_success",
          allow_failure: false,
          job_variables: [],
          root_variables_inheritance: true,
          scheduling_type: :stage
        )
      end
    end

    context 'needs both job and pipeline' do
      let(:needs) { ['build', { pipeline: 'some/project' }] }

      it 'creates jobs with valid specification' do
        expect(subject.builds.size).to eq(2)
        expect(subject.builds[0]).to eq(
          stage: "build",
          stage_idx: 1,
          name: "build",
          only: { refs: %w[branches tags] },
          options: {
            script: ["test"]
          },
          when: "on_success",
          allow_failure: false,
          job_variables: [],
          root_variables_inheritance: true,
          scheduling_type: :stage
        )
        expect(subject.builds[1]).to eq(
          stage: "test",
          stage_idx: 2,
          name: "bridge",
          only: { refs: %w[branches tags] },
          options: {
            bridge_needs: { pipeline: 'some/project' }
          },
          needs_attributes: [
            { name: "build", artifacts: true, optional: false }
          ],
          when: "on_success",
          allow_failure: false,
          job_variables: [],
          root_variables_inheritance: true,
          scheduling_type: :stage
        )
      end
    end

    context 'needs cross projects artifacts' do
      let(:config) do
        {
          build: { stage: 'build', script: 'test' },
          test1: { stage: 'test', script: 'test', needs: needs },
          test2: { stage: 'test', script: 'test' }
        }
      end

      let(:needs) do
        [
          { job: 'build' },
          {
            project: 'some/project',
            ref: 'some/ref',
            job: 'build2',
            artifacts: true
          },
          {
            project: 'some/other/project',
            ref: 'some/ref',
            job: 'build3',
            artifacts: false
          },
          {
            project: 'project',
            ref: 'master',
            job: 'build4'
          }
        ]
      end

      it 'creates jobs with valid specification' do
        expect(subject.builds.size).to eq(3)

        expect(subject.builds[1]).to eq(
          stage: 'test',
          stage_idx: 2,
          name: 'test1',
          options: {
            script: ['test'],
            cross_dependencies: [
              {
                artifacts: true,
                job: 'build2',
                project: 'some/project',
                ref: 'some/ref'
              },
              {
                artifacts: false,
                job: 'build3',
                project: 'some/other/project',
                ref: 'some/ref'
              },
              {
                artifacts: true,
                job: 'build4',
                project: 'project',
                ref: 'master'
              }
            ]
          },
          needs_attributes: [
            { name: 'build', artifacts: true, optional: false }
          ],
          only: { refs: %w[branches tags] },
          when: 'on_success',
          allow_failure: false,
          job_variables: [],
          root_variables_inheritance: true,
          scheduling_type: :dag
        )
      end
    end

    context 'needs cross projects artifacts and pipelines' do
      let(:needs) do
        [
          {
            project: 'some/project',
            ref: 'some/ref',
            job: 'build',
            artifacts: true
          },
          {
            pipeline: 'other/project'
          }
        ]
      end

      it 'returns errors' do
        expect(subject.errors).to include(
          'jobs:bridge config should contain either a trigger or a needs:pipeline')
      end
    end

    context 'with invalid needs cross projects artifacts' do
      let(:config) do
        {
          build: { stage: 'build', script: 'test' },
          test: {
            stage: 'test',
            script: 'test',
            needs: {
              project: 'some/project',
              ref: 1,
              job: 'build',
              artifacts: true
            }
          }
        }
      end

      it 'returns errors' do
        expect(subject.errors).to contain_exactly(
          'jobs:test:needs:need ref should be a string')
      end
    end

    describe 'cross pipeline needs' do
      context 'when job is not present' do
        let(:config) do
          {
            rspec: {
              stage: 'test',
              script: 'rspec',
              needs: [
                { pipeline: '$UPSTREAM_PIPELINE_ID' }
              ]
            }
          }
        end

        it 'returns an error' do
          expect(subject).not_to be_valid
          # This currently shows a confusing error message because a conflict of syntax
          # with upstream pipeline status mirroring: https://gitlab.com/gitlab-org/gitlab/-/issues/280853
          expect(subject.errors).to include(/:needs config uses invalid types: bridge/)
        end
      end
    end

    describe 'with cross project and cross pipeline needs' do
      let(:config) do
        {
          rspec: {
            stage: 'test',
            script: 'rspec',
            needs: [
              { pipeline: '$UPSTREAM_PIPELINE_ID', job: 'test' },
              { project: 'org/the-project', ref: 'master', job: 'build', artifacts: true }
            ]
          }
        }
      end

      it 'returns a valid specification' do
        expect(subject).to be_valid

        rspec = subject.builds.last
        expect(rspec.dig(:options, :cross_dependencies)).to eq(
          [
            { pipeline: '$UPSTREAM_PIPELINE_ID', job: 'test', artifacts: true },
            { project: 'org/the-project', ref: 'master', job: 'build', artifacts: true }
          ])
      end
    end

    describe 'dast configuration' do
      let(:config) do
        { build: { stage: 'build', dast_configuration: { site_profile: 'Site profile', scanner_profile: 'Scanner profile' }, script: 'test' } }
      end

      it 'creates a job with a valid specification' do
        expect(subject.builds[0][:options]).to include(dast_configuration: { site_profile: 'Site profile', scanner_profile: 'Scanner profile' })
      end
    end
  end

  describe 'secrets' do
    let(:secrets) do
      {
        DATABASE_PASSWORD: {
          vault: 'production/db/password'
        }
      }
    end

    let(:config) { { deploy_to_production: { stage: 'deploy', script: ['echo'], secrets: secrets } } }

    subject(:result) { described_class.new(YAML.dump(config)).execute }

    it "returns secrets info" do
      secrets = result.builds.first.fetch(:secrets)

      expect(secrets).to eq({
        DATABASE_PASSWORD: {
          vault: {
            engine: { name: 'kv-v2', path: 'kv-v2' },
            path: 'production/db',
            field: 'password'
          }
        }
      })
    end
  end
end
