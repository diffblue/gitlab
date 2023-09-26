# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :runner, product_group: :security_policies,
    quarantine: {
      only: { subdomain: "staging-ref" },
      type: :investigating,
      issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/423032"
    } do
    describe 'Scan result policy' do
      let!(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = "project-with-scan-result-policy"
          resource.description = 'Project to test scan result policy with secure'
          resource.auto_devops_enabled = false
          resource.initialize_with_readme = true
        end
      end

      let(:tag_name) { "secure_report_#{project.name}" }

      let!(:runner) do
        create(:project_runner, project: project, name: "runner-for-#{project.name}", tags: [tag_name])
      end

      let!(:scan_result_policy_project) do
        EE::Resource::SecurityScanPolicyProject.fabricate_via_api! do |commit|
          commit.project_path = project.full_path
        end
      end

      let!(:policy_project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.group = project.group
          resource.add_name_uuid = false
          resource.name = Pathname.new(scan_result_policy_project.api_response[:full_path]).basename.to_s
        end
      end

      let(:scan_result_policy_name) { 'greyhound' }
      let(:policy_yaml_path) { "qa/ee/fixtures/scan_result_policy_yaml/scan_result_policy.yml" }
      let(:premade_report_name) { "gl-container-scanning-report.json" }
      let(:premade_report_path) { "qa/ee/fixtures/secure_premade_reports/gl-container-scanning-report.json" }
      let(:commit_branch) { "new_branch_#{SecureRandom.hex(8)}" }
      let!(:approver) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:scan_result_policy_commit) do
        EE::Resource::ScanResultPolicyCommit.fabricate_via_api! do |commit|
          commit.policy_name = scan_result_policy_name
          commit.project_path = project.full_path
          commit.mode = :APPEND
          commit.policy_yaml = begin
            yaml_obj = YAML.load_file(policy_yaml_path)
            yaml_obj["actions"].first["user_approvers_ids"][0] = approver.id
            yaml_obj
          end
        end
      end

      before do
        project.add_member(approver)
        scan_result_policy_commit # fabricate scan result policy commit

        Flow::Login.sign_in
        project.visit!
      end

      after do
        runner.remove_via_api!
      end

      it 'requires approval when a pipeline report has findings matching the scan result policy', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/365005' do
        # Make sure Scan result policy commit was successful before running examples
        expect(scan_result_policy_commit.api_response).to have_key(:branch)
        expect(scan_result_policy_commit.api_response[:branch]).not_to be nil

        create_scan_result_policy
        # Create a branch and a commit to trigger a pipeline to generate container scanning findings
        create_commit(branch_name: commit_branch, report_name: premade_report_name,
          report_path: premade_report_path, severity: "Critical")

        merge_request = create_test_mr
        Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
        merge_request.visit!

        Page::MergeRequest::Show.perform do |mr|
          expect(mr).not_to be_mergeable
          expect(mr.approvals_required_from).to include(scan_result_policy_name)
        end
      end

      it 'does not block merge when scan result policy does not apply for pipeline security findings',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/423412' do
        # Make sure Scan result policy commit was successful before running examples
        expect(scan_result_policy_commit.api_response).to have_key(:branch)
        expect(scan_result_policy_commit.api_response[:branch]).not_to be nil

        create_scan_result_policy

        # Create a branch and a commit to trigger a pipeline to generate container scanning findings
        create_commit(branch_name: commit_branch, report_name: premade_report_name,
          report_path: premade_report_path, severity: "High")

        merge_request = create_test_mr
        Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
        merge_request.visit!

        Page::MergeRequest::Show.perform do |mr|
          expect(mr).to be_mergeable
          expect(page.has_text?('Approval is optional')).to be true
        end
      end

      def ci_file(report_name)
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            include:
              template: Container-Scanning.gitlab-ci.yml
              template: SAST.gitlab-ci.yml

            container_scanning:
              tags: [#{tag_name}]
              only: null # Template defaults to feature branches only
              variables:
                GIT_STRATEGY: fetch # Template defaults to none, which stops fetching the premade report
              script:
                - echo "Skipped"
              artifacts:
                reports:
                  container_scanning: #{report_name}
          YAML
        }
      end

      def create_scan_result_policy
        branch_name = scan_result_policy_commit.api_response[:branch]
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.no_preparation = true
          merge_request.project = policy_project
          merge_request.target_new_branch = false
          merge_request.source_branch = branch_name
        end.merge_via_api!
      end

      def create_test_mr
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.no_preparation = true
          merge_request.project = project
          merge_request.target_new_branch = false
          merge_request.source_branch = commit_branch
        end
      end

      def report_file(report_name:, report_path:, severity:)
        {
          file_path: report_name.to_s,
          content: container_scanning_report_content(report_path, severity)
        }
      end

      def container_scanning_report_content(report_path, severity)
        if severity == "High"
          File.read(report_path.to_s).gsub("Critical", severity)
        else
          File.read(report_path.to_s)
        end
      end

      def create_commit(branch_name:, report_name:, report_path:, severity: )
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.start_branch = project.default_branch
          commit.branch = branch_name
          commit.commit_message = 'Add premade container scanning report'
          commit.add_files([ci_file(report_name), report_file(report_name: report_name,
            report_path: report_path, severity: severity)])
        end
      end
    end
  end
end
