# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Data Stores', product_group: :global_search do
    describe(
      'When using elasticsearch API to search for a public note',
      :orchestrated,
      :elasticsearch,
      except: :production
    ) do
      include_context 'advanced search active'

      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue for note index test'
        end
      end

      let(:note) do
        Resource::ProjectIssueNote.fabricate_via_api! do |project_issue_note|
          project_issue_note.project = issue.project
          project_issue_note.issue = issue
          project_issue_note.body = "This is a comment with a unique number #{SecureRandom.hex(8)}"
        end
      end

      it(
        'finds note that matches note body',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347634'
      ) do
        QA::Support::Retrier.retry_on_exception(
          max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
          sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
        ) do
          get(Runtime::Search.create_search_request(api_client, 'notes', note.body).url)
          aggregate_failures do
            expect_status(QA::Support::API::HTTP_STATUS_OK)
            expect(json_body).not_to be_empty
            expect(json_body[0][:body]).to eq(note.body)
            expect(json_body[0][:noteable_id]).to eq(issue.id)
          end
        end
      end
    end
  end
end
