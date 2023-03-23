# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Pipeline subscription with a group owned project', :runner, product_group: :pipeline_execution do
      let(:executor) { "qa-runner-#{SecureRandom.hex(3)}" }
      let(:tag_name) { "awesome-tag-#{SecureRandom.hex(3)}" }

      let(:group) do
        Resource::Group.fabricate_via_api! do |group|
          group.name = "group-for-pipeline-subscriptions-#{SecureRandom.hex(3)}"
        end
      end

      let(:upstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = 'upstream-project-for-subscription'
          project.description = 'Project with CI subscription'
        end
      end

      let(:downstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = 'project-with-pipeline-subscription'
          project.description = 'Project with CI subscription'
        end
      end

      let!(:runner) do
        Resource::GroupRunner.fabricate! do |runner|
          runner.group = group
          runner.name = executor
          runner.tags = [executor]
        end
      end

      before do
        [downstream_project, upstream_project].each do |project|
          add_ci_file(project)
        end

        Flow::Login.sign_in
        downstream_project.visit!

        EE::Resource::PipelineSubscriptions.fabricate_via_browser_ui! do |subscription|
          subscription.project_path = upstream_project.path_with_namespace
        end
      end

      after do
        [runner, upstream_project, downstream_project, group].each do |item|
          item.remove_via_api!
        end
      end

      context 'when upstream project new tag pipeline finishes' do
        it 'triggers pipeline in downstream project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347998' do
          # Downstream project should have one pipeline at this time
          Support::Waiter.wait_until { downstream_project.pipelines.size == 1 }

          Resource::Tag.fabricate_via_api! do |tag|
            tag.project = upstream_project
            tag.ref = upstream_project.default_branch
            tag.name = tag_name
          end

          downstream_project.visit!

          Support::Waiter.wait_until(sleep_interval: 3) do
            QA::Runtime::Logger.info 'Waiting for upstream pipeline to succeed.'
            new_pipeline = upstream_project.pipelines.find { |pipeline| pipeline[:ref] == tag_name }
            new_pipeline&.dig(:status) == 'success'
          end

          Page::Project::Menu.perform(&:go_to_pipelines)

          # Downstream project must have 2 pipelines at this time
          expect { downstream_project.pipelines.size }.to eventually_eq(2), "There are currently #{downstream_project.pipelines.size} pipelines in downstream project."

          # expect new downstream pipeline to also succeed
          Page::Project::Pipeline::Index.perform do |index|
            expect(index.wait_for_latest_pipeline(status: 'passed')).to be_truthy, 'Downstream pipeline did not succeed as expected.'
          end
        end
      end

      private

      def add_ci_file(project)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  job:
                    tags:
                      - #{executor}
                    script:
                      - echo DONE!
                YAML
              }
            ]
          )
        end
      end
    end
  end
end
