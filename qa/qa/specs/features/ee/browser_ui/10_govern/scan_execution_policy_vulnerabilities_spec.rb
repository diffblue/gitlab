# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :runner, product_group: :security_policies do
    describe 'Scan execution policy' do
      let!(:project) do
        create(:project, :with_readme, name: 'project-with-scan-execution-policy')
      end

      let!(:runner) do
        create(:project_runner, project: project, name: "runner-for-#{project.name}")
      end

      let!(:scan_execution_policy_project) do
        EE::Resource::SecurityScanPolicyProject.fabricate_via_api! do |commit|
          commit.project_path = project.full_path
        end
      end

      let!(:policy_project) do
        create(:project,
          group: project.group,
          add_name_uuid: false,
          name: Pathname.new(scan_execution_policy_project.api_response[:full_path]).basename.to_s)
      end

      let(:scan_execution_policy_name) { 'greyhound' }
      let(:policy_yaml_path) do
        Pathname.new(EE::Runtime::Path.fixture('scan_execution_policy_yaml/scan_execution_policy_schedule.yml'))
      end

      let(:job_name) { 'secret-detection-0' }

      let(:scan_execution_policy_commit) do
        EE::Resource::ScanResultPolicyCommit.fabricate_via_api! do |commit|
          commit.policy_name = scan_execution_policy_name
          commit.project_path = project.full_path
          commit.mode = :APPEND
          commit.policy_yaml = YAML.load_file(policy_yaml_path)
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        scan_execution_policy_commit # fabricate scan execution policy commit
      end

      after do
        runner.remove_via_api!
      end

      it 'scan execution policy takes effect when pipeline is run on the main branch',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/423944' do
        expect(scan_execution_policy_commit.api_response).to have_key(:branch)
        expect(scan_execution_policy_commit.api_response[:branch]).not_to be nil

        create_scan_execution_policy

        create_commit
        # Check that secret-detection job is triggered whenever there is a pipeline is triggered on main
        check_pipeline_for_job
      end

      private

      def create_scan_execution_policy
        branch_name = scan_execution_policy_commit.api_response[:branch]
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.no_preparation = true
          merge_request.project = policy_project
          merge_request.target_new_branch = false
          merge_request.source_branch = branch_name
        end.merge_via_api!
      end

      def check_pipeline_for_job
        Flow::Pipeline.wait_for_latest_pipeline(status: 'warning')
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.has_job?(job_name)
        end
      end

      def ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test:
              script: echo "Test job"
          YAML
        }
      end

      def test_file
        {
          file_path: 'abc.py',
          content: <<~TXT
            import os
            os.getenv('QA_RUN_TYPE')
          TXT
        }
      end

      def create_commit
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Commit files to default branch'
          commit.add_files([ci_file, test_file])
        end
      end
    end
  end
end
