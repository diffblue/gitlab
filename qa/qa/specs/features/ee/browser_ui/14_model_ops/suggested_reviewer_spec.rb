# frozen_string_literal: true

module QA
  RSpec.describe 'ModelOps', :skip_live_env do
    describe 'Suggested Reviewers' do
      let(:project) { build(:project, path_with_namespace: 'gitlab-org/gitlab-qa').reload! }

      let(:merge_request) do
        Resource::MergeRequest.init do |merge_request|
          merge_request.project = project
          merge_request.iid = merge_request_iid
        end.reload!
      end

      let(:merge_request_iid) do
        case Runtime::Env.ci_project_name
        when 'production', 'canary'
          1056
        else
          raise 'This test only runs on Production'
        end
      end

      before do
        Flow::Login.sign_in
        merge_request.visit!
      end

      after do
        Page::MergeRequest::Show.perform do |mr|
          Support::Retrier.retry_until(max_duration: 30,
            sleep_interval: 5,
            message: 'There should be no reviewers assigned') do
            mr.unassign_reviewers
            mr.has_no_reviewers?
          end
        end
      end

      # This test uses a merge request that was manually created in the GitLab QA project on Production.
      #
      # It can't be run in the dot com environments using new blank projects because model training takes time after
      # the suggested reviewers feature is enabled.
      it 'suggests reviewers',
        product_group: :applied_ml,
        only: { pipeline: %i[production canary] },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377613' do
        Page::MergeRequest::Show.perform do |mr|
          suggested_reviewers = mr.suggested_reviewer_usernames

          expect(suggested_reviewers.size).to be >= 1

          reviewer = suggested_reviewers.find { |sr| sr[:username] == 'mlaspierre' }
          if reviewer
            mr.select_reviewer(reviewer[:username])

            expect(mr).to have_reviewer(reviewer[:name])
          else
            mr.toggle_reviewers_edit
          end
        end
      end
    end
  end
end
