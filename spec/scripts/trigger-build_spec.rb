# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../scripts/trigger-build'

RSpec.describe Trigger do
  let(:env) do
    {
      'CI_JOB_URL' => 'ci_job_url',
      'CI_PROJECT_PATH' => 'ci_project_path',
      'CI_COMMIT_REF_NAME' => 'ci_commit_ref_name',
      'CI_COMMIT_REF_SLUG' => 'ci_commit_ref_slug',
      'CI_COMMIT_SHA' => 'ci_commit_sha',
      'CI_MERGE_REQUEST_PROJECT_ID' => 'ci_merge_request_project_id',
      'CI_MERGE_REQUEST_IID' => 'ci_merge_request_iid',
      'GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN' => 'bot-token',
      'CI_JOB_TOKEN' => 'job-token',
      'GITLAB_USER_NAME' => 'gitlab_user_name'
    }
  end

  before do
    stub_env(env)
  end

  describe Trigger::Base do
    describe '#invoke!' do
      it 'raises a NotImplementedError' do
        expect { described_class.new.invoke! }.to raise_error(NotImplementedError)
      end
    end

    describe '#variables' do
      let(:simple_forwarded_variables) do
        {
          'TRIGGER_SOURCE' => env['CI_JOB_URL'],
          'TOP_UPSTREAM_SOURCE_PROJECT' => env['CI_PROJECT_PATH'],
          'TOP_UPSTREAM_SOURCE_REF' => env['CI_COMMIT_REF_NAME'],
          'TOP_UPSTREAM_SOURCE_JOB' => env['CI_JOB_URL'],
          'TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID' => env['CI_MERGE_REQUEST_PROJECT_ID'],
          'TOP_UPSTREAM_MERGE_REQUEST_IID' => env['CI_MERGE_REQUEST_IID']
        }
      end

      it 'includes simple forwarded variables' do
        expect(subject.variables).to include(simple_forwarded_variables)
      end

      describe "#base_variables" do
        context 'when CI_COMMIT_TAG is true' do
          before do
            stub_env('CI_COMMIT_TAG', true)
          end

          it 'sets GITLAB_REF_SLUG to CI_COMMIT_REF_NAME' do
            expect(subject.variables['GITLAB_REF_SLUG']).to eq(env['CI_COMMIT_REF_NAME'])
          end
        end

        context 'when CI_COMMIT_TAG is false' do
          before do
            stub_env('CI_COMMIT_TAG', false)
          end

          it 'sets GITLAB_REF_SLUG to CI_COMMIT_REF_SLUG' do
            expect(subject.variables['GITLAB_REF_SLUG']).to eq(env['CI_COMMIT_REF_SLUG'])
          end
        end

        context 'when TRIGGERED_USER is set' do
          before do
            stub_env('TRIGGERED_USER', 'triggered_user')
          end

          it 'sets TRIGGERED_USER to triggered_user' do
            expect(subject.variables['TRIGGERED_USER']).to eq('triggered_user')
          end
        end

        context 'when TRIGGERED_USER is not set' do
          before do
            stub_env('TRIGGERED_USER', nil)
          end

          it 'sets TRIGGERED_USER to GITLAB_USER_NAME' do
            expect(subject.variables['TRIGGERED_USER']).to eq(env['GITLAB_USER_NAME'])
          end
        end

        context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is set' do
          before do
            stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', 'ci_merge_request_source_branch_sha')
          end

          it 'sets TOP_UPSTREAM_SOURCE_SHA to ci_merge_request_source_branch_sha' do
            expect(subject.variables['TOP_UPSTREAM_SOURCE_SHA']).to eq('ci_merge_request_source_branch_sha')
          end
        end

        context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is set as empty' do
          before do
            stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', '')
          end

          it 'sets TOP_UPSTREAM_SOURCE_SHA to CI_COMMIT_SHA' do
            expect(subject.variables['TOP_UPSTREAM_SOURCE_SHA']).to eq(env['CI_COMMIT_SHA'])
          end
        end

        context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is not set' do
          before do
            stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', nil)
          end

          it 'sets TOP_UPSTREAM_SOURCE_SHA to CI_COMMIT_SHA' do
            expect(subject.variables['TOP_UPSTREAM_SOURCE_SHA']).to eq(env['CI_COMMIT_SHA'])
          end
        end
      end

      describe "#version_file_variables" do
        using RSpec::Parameterized::TableSyntax

        where(:version_file, :version) do
          'GITALY_SERVER_VERSION'                | "1"
          'GITLAB_ELASTICSEARCH_INDEXER_VERSION' | "2"
          'GITLAB_KAS_VERSION'                   | "3"
          'GITLAB_PAGES_VERSION'                 | "4"
          'GITLAB_SHELL_VERSION'                 | "5"
          'GITLAB_WORKHORSE_VERSION'             | "6"
        end

        with_them do
          context "when set in ENV" do
            before do
              stub_env(version_file, version)
            end

            it 'includes the version from ENV' do
              expect(subject.variables[version_file]).to eq(version)
            end
          end

          context "when set in a file" do
            before do
              allow(File).to receive(:read).and_call_original
            end

            it 'includes the version from the file' do
              expect(File).to receive(:read).with(version_file).and_return(version)
              expect(subject.variables[version_file]).to eq(version)
            end
          end
        end
      end
    end
  end

  describe Trigger::Omnibus do
    let(:env) do
      super().merge(
        'QA_IMAGE' => 'qa_image',
        'OMNIBUS_GITLAB_PROJECT_ACCESS_TOKEN' => nil,
        'OMNIBUS_GITLAB_CACHE_UPDATE' => 'omnibus_gitlab_cache_update',
        'GITLAB_QA_OPTIONS' => 'gitlab_qa_options',
        'QA_TESTS' => 'qa_tests',
        'ALLURE_JOB_NAME' => 'allure_job_name'
      )
    end

    let(:downstream_project_path) { 'gitlab-org/build/omnibus-gitlab-mirror' }
    let(:ref) { 'master' }
    let(:stubbed_gitlab_client) { double }
    let(:stubbed_pipeline) { Struct.new(:id, :web_url).new(42, 'pipeline_url') }
    let(:gitlab_client_private_token) { env['GITLAB_BOT_MULTI_PROJECT_PIPELINE_POLLING_TOKEN'] }

    describe '#invoke!' do
      let(:extra_variables) do
        {
          'QA_IMAGE' => env['QA_IMAGE'],
          'SKIP_QA_DOCKER' => 'true',
          'ALTERNATIVE_SOURCES' => 'true',
          'CACHE_UPDATE' => env['OMNIBUS_GITLAB_CACHE_UPDATE'],
          'GITLAB_QA_OPTIONS' => env['GITLAB_QA_OPTIONS'],
          'QA_TESTS' => env['QA_TESTS'],
          'ALLURE_JOB_NAME' => env['ALLURE_JOB_NAME']
        }
      end

      before do
        allow(subject).to receive(:puts)
        allow(Gitlab).to receive(:client)
          .with(
            endpoint: 'https://gitlab.com/api/v4',
            private_token: gitlab_client_private_token
          )
          .and_return(stubbed_gitlab_client)
      end

      def expect_run_trigger_with_params(variables = {})
        expect(stubbed_gitlab_client).to receive(:run_trigger)
          .with(
            downstream_project_path,
            env['CI_JOB_TOKEN'],
            ref,
            hash_including(variables)
          )
          .and_return(stubbed_pipeline)
      end

      context 'when OMNIBUS_GITLAB_PROJECT_ACCESS_TOKEN is set' do
        let(:gitlab_client_private_token) { 'omnibus_gitlab_project_access_token' }

        before do
          stub_env('OMNIBUS_GITLAB_PROJECT_ACCESS_TOKEN', gitlab_client_private_token)
        end

        it 'triggers the pipeline on the correct project' do
          expect_run_trigger_with_params

          subject.invoke!
        end
      end

      it 'invokes the trigger with expected variables' do
        expect_run_trigger_with_params(extra_variables)

        subject.invoke!
      end

      context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is set' do
        before do
          stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', 'ci_merge_request_source_branch_sha')
        end

        it 'sets GITLAB_VERSION & IMAGE_TAG to ci_merge_request_source_branch_sha' do
          expect_run_trigger_with_params(
            'GITLAB_VERSION' => 'ci_merge_request_source_branch_sha',
            'IMAGE_TAG' => 'ci_merge_request_source_branch_sha'
          )

          subject.invoke!
        end
      end

      context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is set as empty' do
        before do
          stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', '')
        end

        it 'sets GITLAB_VERSION & IMAGE_TAG to CI_COMMIT_SHA' do
          expect_run_trigger_with_params(
            'GITLAB_VERSION' => env['CI_COMMIT_SHA'],
            'IMAGE_TAG' => env['CI_COMMIT_SHA']
          )

          subject.invoke!
        end
      end

      context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is not set' do
        it 'sets GITLAB_VERSION & IMAGE_TAG to CI_COMMIT_SHA' do
          expect_run_trigger_with_params(
            'GITLAB_VERSION' => env['CI_COMMIT_SHA'],
            'IMAGE_TAG' => env['CI_COMMIT_SHA']
          )

          subject.invoke!
        end
      end

      context 'when Trigger.security? is true' do
        before do
          allow(Trigger).to receive(:security?).and_return(true)
        end

        it 'sets SECURITY_SOURCES to true' do
          expect_run_trigger_with_params('SECURITY_SOURCES' => 'true')

          subject.invoke!
        end
      end

      context 'when Trigger.security? is false' do
        before do
          allow(Trigger).to receive(:security?).and_return(false)
        end

        it 'sets SECURITY_SOURCES to false' do
          expect_run_trigger_with_params('SECURITY_SOURCES' => 'false')

          subject.invoke!
        end
      end

      context 'when Trigger.ee? is true' do
        before do
          allow(Trigger).to receive(:ee?).and_return(true)
        end

        it 'sets ee to true' do
          expect_run_trigger_with_params('ee' => 'true')

          subject.invoke!
        end
      end

      context 'when Trigger.ee? is false' do
        before do
          allow(Trigger).to receive(:ee?).and_return(false)
        end

        it 'sets ee to false' do
          expect_run_trigger_with_params('ee' => 'false')

          subject.invoke!
        end
      end

      context 'when QA_BRANCH is set' do
        before do
          stub_env('QA_BRANCH', 'qa_branch')
        end

        it 'sets QA_BRANCH to qa_branch' do
          expect_run_trigger_with_params('QA_BRANCH' => 'qa_branch')

          subject.invoke!
        end
      end

      context 'when OMNIBUS_PROJECT_PATH is set' do
        let(:downstream_project_path) { 'omnibus_project_path' }

        before do
          stub_env('OMNIBUS_PROJECT_PATH', downstream_project_path)
        end

        it 'triggers the pipeline on the correct project' do
          expect_run_trigger_with_params

          subject.invoke!
        end
      end

      context 'when OMNIBUS_BRANCH is set' do
        let(:ref) { 'omnibus_branch' }

        before do
          stub_env('OMNIBUS_BRANCH', ref)
        end

        it 'triggers the pipeline on the correct ref' do
          expect_run_trigger_with_params

          subject.invoke!
        end
      end

      context 'when CI_MERGE_REQUEST_TARGET_BRANCH_NAME is a stable branch' do
        let(:ref) { '14-10-stable' }

        before do
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', "#{ref}-ee")
        end

        it 'triggers the pipeline on the correct ref' do
          expect_run_trigger_with_params

          subject.invoke!
        end
      end

      it 'waits for downstream pipeline' do
        expect_run_trigger_with_params
        expect(Trigger::Pipeline).to receive(:new)
          .with(downstream_project_path, stubbed_pipeline.id, stubbed_gitlab_client)

        subject.invoke!
      end

      context 'with post_comment: true' do
        before do
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', "#{ref}-ee")
        end

        it 'posts a comment' do
          expect_run_trigger_with_params
          expect(Trigger::CommitComment).to receive(:post!).with(stubbed_pipeline, stubbed_gitlab_client)

          subject.invoke!(post_comment: true)
        end
      end

      context 'with downstream_job_name: "foo"' do
        let(:downstream_job) { Struct.new(:id, :name).new(42, 'foo') }
        let(:paginated_resources) { Struct.new(:auto_paginate).new([downstream_job]) }

        before do
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', "#{ref}-ee")
        end

        it 'fetches the downstream job' do
          expect_run_trigger_with_params
          expect(stubbed_gitlab_client).to receive(:pipeline_jobs)
            .with(downstream_project_path, stubbed_pipeline.id).and_return(paginated_resources)
          expect(Trigger::Job).to receive(:new).with(downstream_project_path, downstream_job.id, stubbed_gitlab_client)

          subject.invoke!(downstream_job_name: 'foo')
        end
      end
    end
  end

  describe Trigger::CNG do
    describe '#variables' do
      it 'does not include redundant variables' do
        expect(subject.variables).not_to include('TRIGGER_SOURCE', 'TRIGGERED_USER')
      end

      it 'invokes the trigger with expected variables' do
        expect(subject.variables).to include('FORCE_RAILS_IMAGE_BUILDS' => 'true')
      end

      describe "TRIGGER_BRANCH" do
        context 'when CNG_BRANCH is not set' do
          it 'sets TRIGGER_BRANCH to master' do
            expect(subject.variables['TRIGGER_BRANCH']).to eq('master')
          end
        end

        context 'when CNG_BRANCH is set' do
          let(:ref) { 'cng_branch' }

          before do
            stub_env('CNG_BRANCH', ref)
          end

          it 'sets TRIGGER_BRANCH to cng_branch' do
            expect(subject.variables['TRIGGER_BRANCH']).to eq(ref)
          end
        end

        context 'when CI_MERGE_REQUEST_TARGET_BRANCH_NAME is a stable branch' do
          let(:ref) { '14-10-stable' }

          before do
            stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', "#{ref}-ee")
          end

          it 'sets TRIGGER_BRANCH to 14-10-stable' do
            expect(subject.variables['TRIGGER_BRANCH']).to eq(ref)
          end
        end
      end

      describe "GITLAB_VERSION" do
        context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is set' do
          before do
            stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', 'ci_merge_request_source_branch_sha')
          end

          it 'sets GITLAB_VERSION to ci_merge_request_source_branch_sha' do
            expect(subject.variables['GITLAB_VERSION']).to eq('ci_merge_request_source_branch_sha')
          end
        end

        context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is set as empty' do
          before do
            stub_env('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', '')
          end

          it 'sets GITLAB_VERSION to CI_COMMIT_SHA' do
            expect(subject.variables['GITLAB_VERSION']).to eq(env['CI_COMMIT_SHA'])
          end
        end

        context 'when CI_MERGE_REQUEST_SOURCE_BRANCH_SHA is not set' do
          it 'sets GITLAB_VERSION to CI_COMMIT_SHA' do
            expect(subject.variables['GITLAB_VERSION']).to eq(env['CI_COMMIT_SHA'])
          end
        end
      end

      describe "GITLAB_TAG" do
        context 'when CI_COMMIT_TAG is true' do
          before do
            stub_env('CI_COMMIT_TAG', true)
          end

          it 'sets GITLAB_TAG to true' do
            expect(subject.variables['GITLAB_TAG']).to eq(true)
          end
        end

        context 'when CI_COMMIT_TAG is false' do
          before do
            stub_env('CI_COMMIT_TAG', false)
          end

          it 'sets GITLAB_TAG to false' do
            expect(subject.variables['GITLAB_TAG']).to eq(false)
          end
        end
      end

      describe "GITLAB_ASSETS_TAG" do
        context 'when CI_COMMIT_TAG is true' do
          before do
            stub_env('CI_COMMIT_TAG', true)
          end

          it 'sets GITLAB_ASSETS_TAG to CI_COMMIT_REF_NAME' do
            expect(subject.variables['GITLAB_ASSETS_TAG']).to eq(env['CI_COMMIT_REF_NAME'])
          end
        end

        context 'when CI_COMMIT_TAG is false' do
          before do
            stub_env('CI_COMMIT_TAG', false)
          end

          it 'sets GITLAB_ASSETS_TAG to CI_COMMIT_SHA' do
            expect(subject.variables['GITLAB_ASSETS_TAG']).to eq(env['CI_COMMIT_SHA'])
          end
        end
      end

      describe "CE_PIPELINE" do
        context 'when Trigger.ee? is true' do
          before do
            allow(Trigger).to receive(:ee?).and_return(true)
          end

          it 'sets ee to true' do
            expect(subject.variables['CE_PIPELINE']).to eq(nil)
          end
        end

        context 'when Trigger.ee? is false' do
          before do
            allow(Trigger).to receive(:ee?).and_return(false)
          end

          it 'sets ee to false' do
            expect(subject.variables['CE_PIPELINE']).to eq('true')
          end
        end
      end

      describe "EE_PIPELINE" do
        context 'when Trigger.ee? is true' do
          before do
            allow(Trigger).to receive(:ee?).and_return(true)
          end

          it 'sets ee to true' do
            expect(subject.variables['EE_PIPELINE']).to eq('true')
          end
        end

        context 'when Trigger.ee? is false' do
          before do
            allow(Trigger).to receive(:ee?).and_return(false)
          end

          it 'sets ee to false' do
            expect(subject.variables['EE_PIPELINE']).to eq(nil)
          end
        end
      end

      describe "#version_param_value" do
        using RSpec::Parameterized::TableSyntax

        let(:version_file) { 'GITALY_SERVER_VERSION' }

        where(:raw_version, :expected_version) do
          "1.2.3" | "v1.2.3"
          "1.2.3-rc1" | "v1.2.3-rc1"
          "1.2.3-ee" | "v1.2.3-ee"
          "1.2.3-rc1-ee" | "v1.2.3-rc1-ee"
        end

        with_them do
          context "when set in ENV" do
            before do
              stub_env(version_file, raw_version)
            end

            it 'includes the version from ENV' do
              expect(subject.variables[version_file]).to eq(expected_version)
            end
          end
        end
      end
    end
  end
end
