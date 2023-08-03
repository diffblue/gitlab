# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :runner, product_group: :threat_insights do
    describe 'Dismissed vulnerabilities in MR security widget' do
      let(:secret_detection_report) { "gl-secret-detection-report.json" }
      let(:secret_detection_report_mr) { "gl-secret-detection-report-mr.json" }

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-vulnerabilities'
          project.description = 'To test dismissed vulnerabilities in MR widget'
        end
      end

      let!(:artefacts_directory) do
        Pathname.new(EE::Runtime::Path.fixture('dismissed_security_findings_mr_widget'))
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = "runner-for-#{project.name}"
          runner.tags = ['secure_report']
        end
      end

      let!(:repository) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add report files'
          commit.add_directory(artefacts_directory)
        end
      end

      let!(:ci_yaml_commit) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([ci_file(secret_detection_report)])
        end
      end

      let(:source_mr_repository) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = 'test-dismissed-vulnerabilities'
          commit.start_branch = project.default_branch
          commit.commit_message = 'New secrete detection findings report in yml file'
          commit.update_files([ci_file(secret_detection_report_mr)])
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.source = source_mr_repository
          mr.source_branch = 'test-dismissed-vulnerabilities'
          mr.target_branch = project.default_branch
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
      end

      after do
        runner.remove_via_api!
      end

      it 'checks that dismissed vulnerabilities do not show up in MR security widget', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415291' do
        Page::Project::Menu.perform(&:go_to_vulnerability_report)

        EE::Page::Project::Secure::SecurityDashboard.perform do |security_dashboard|
          security_dashboard.wait_for_vuln_report_to_load
          security_dashboard.select_all_vulnerabilities
          security_dashboard.change_state('dismissed', 'not_applicable')
        end

        merge_request.project.visit! # Hoping that the merge_request object will be fully fabricated before visit!
        wait_for_mr_pipeline_success
        merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_vulnerability_report
          merge_request.expand_vulnerability_report
          expect(merge_request).to have_vulnerability_count(2)
          expect(merge_request).to have_secret_detection_vulnerability_count_of(2)
        end
      end

      private

      def wait_for_mr_pipeline_success
        Support::Retrier.retry_until(max_duration: 10, message: "Waiting for MR pipeline to complete",
          sleep_interval: 2) do
          pipeline = project.pipelines.find { |item| item[:source] == "merge_request_event" }
          pipeline[:status] == "success" if pipeline
        end
      end

      def ci_file(report_name)
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            workflow:
              rules:
                - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
                - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

            include:
              template: Jobs/Secret-Detection.latest.gitlab-ci.yml

            secret_detection:
              tags: [secure_report]
              script:
                - echo "Skipped"
              artifacts:
                reports:
                  secret_detection: #{report_name}
          YAML
        }
      end
    end
  end
end
