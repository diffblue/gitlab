# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'In merge trains' do
      context 'new thread discussion' do
        let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
        let!(:runner) do
          Resource::ProjectRunner.fabricate! do |runner|
            runner.project = project
            runner.name = executor
            runner.tags = [executor]
          end
        end

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'pipeline-for-merge-trains'
          end
        end

        let(:merge_request) do
          Resource::MergeRequest.fabricate_via_api! do |merge_request|
            merge_request.project = project
            merge_request.description = Faker::Lorem.sentence
            merge_request.target_new_branch = false
            merge_request.file_name = 'custom_file.txt'
            merge_request.file_content = Faker::Lorem.sentence
          end
        end

        before do
          Flow::Login.sign_in
          project.visit!

          Flow::MergeRequest.enable_merge_trains
          Page::Project::Menu.perform(&:go_to_merge_request_settings)
          Page::Project::Settings::MergeRequest.perform(&:enable_merge_if_all_disscussions_are_resolved)

          commit_ci_file

          merge_request.visit!
          Page::MergeRequest::Show.perform do |show|
            show.has_pipeline_status?('passed')
            show.try_to_merge!
          end
        end

        after do
          runner.remove_via_api!
        end

        it 'does not drop MR', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348084' do
          start_discussion

          Page::MergeRequest::Show.perform do |show|
            show.has_pipeline_status?('passed')
            expect(show).to be_merged
          end
        end

        private

        def commit_ci_file
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files(
              [
                {
                    file_path: '.gitlab-ci.yml',
                    content: <<~YAML
                        test_merge_train:
                          tags:
                            - #{executor}
                          script:
                          - sleep 10
                          - echo 'OK!'
                          only:
                            - merge_requests
                    YAML
                }
              ]
            )
          end
        end

        def start_discussion
          Page::MergeRequest::Show.perform do |show|
            show.wait_until(reload: false) do
              show.has_content? 'started a merge train'
            end
            show.click_discussions_tab
            show.start_discussion(Faker::Lorem.sentence)
          end
        end
      end
    end
  end
end
