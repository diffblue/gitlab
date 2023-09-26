# frozen_string_literal: true

module QA
  RSpec.describe 'Release', product_group: :release do
    describe 'Operations Dashboard' do
      let!(:runner) do
        create(:group_runner, group: group, name: group.name, tags: [group.name])
      end

      let(:group) { create(:group) }
      let(:project_with_success_run) { create(:project, name: 'project-with-success-run', group: group) }
      let(:project_with_pending_run) { create(:project, name: 'project-with-pending-run', group: group) }
      let(:project_without_ci) { create(:project, name: 'project-without-ci', group: group) }
      let(:project_with_failed_run) { create(:project, name: 'project-with-failed-run', group: group) }

      before do
        Flow::Login.sign_in
        setup_projects
        Page::Main::Menu.perform(&:go_to_operations)
      end

      after do
        runner.remove_via_api!
      end

      it 'has many pipelines with appropriate statuses',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348072',
        quarantine: {
          type: :flaky,
          issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/424230"
        } do
        add_projects_to_board

        EE::Page::OperationsDashboard.perform do |operation|
          {
            'project-with-success-run' => 'Passed',
            'project-with-failed-run' => 'Failed',
            'project-with-pending-run' => 'Pending',
            'project-without-ci' => nil
          }.each do |project_name, status|
            project = operation.find_project_card_by_name(project_name)

            if project_name == 'project-without-ci'
              expect(project).to have_content('The branch for this project has no active pipeline configuration.')
            else
              expect(operation.pipeline_status(project)).to eq(status)
            end
          end
        end
      end

      private

      def commit_ci_file(project, file, status)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([file])
        end

        wait_for_pipeline(project, status)
      end

      def setup_projects
        commit_ci_file(project_with_success_run, ci_file_with_tag, 'success')
        commit_ci_file(project_with_pending_run, ci_file_without_existing_tag, 'pending')
        commit_ci_file(project_with_failed_run, ci_file_failed_run, 'failed')
      end

      def wait_for_pipeline(project, status)
        Support::Waiter.wait_until do
          pipelines = project.pipelines
          !pipelines.empty? && pipelines.last[:status] == status
        end
      end

      def add_projects_to_board
        [project_with_success_run, project_with_pending_run, project_without_ci, project_with_failed_run]
          .each do |project|
          EE::Page::OperationsDashboard.perform do |operation|
            operation.add_project(project.name)
            expect(operation).to have_project_card
          end
        end
      end

      def ci_file_with_tag
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test-success:
              tags: ["#{group.name}"]
              script: echo 'OK'
          YAML
        }
      end

      def ci_file_without_existing_tag
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test-pending:
              tags: ['does-not-exist']
              script: echo 'OK'
          YAML
        }
      end

      def ci_file_failed_run
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test-fail:
              tags: ["#{group.name}"]
              script: exit 1
          YAML
        }
      end
    end
  end
end
