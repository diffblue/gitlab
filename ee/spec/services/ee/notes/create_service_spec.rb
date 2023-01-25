# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::CreateService, feature_category: :team_planning do
  context 'note with commands' do
    let(:project) { create(:project) }
    let(:note_params) { opts }

    let_it_be(:user) { create(:user) }

    context 'for issues', feature_category: :team_planning do
      let(:issuable) { create(:issue, project: project, weight: 10) }
      let(:opts) { { noteable_type: 'Issue', noteable_id: issuable.id } }

      it_behaves_like 'issuable quick actions' do
        let(:quick_actions) do
          [
            QuickAction.new(
              action_text: '/weight 5',
              expectation: ->(noteable, can_use_quick_action) {
                expect(noteable.weight == 5).to eq(can_use_quick_action)
              }
            ),
            QuickAction.new(
              action_text: '/clear_weight',
              expectation: ->(noteable, can_use_quick_action) {
                if can_use_quick_action
                  expect(noteable.weight).to be_nil
                else
                  expect(noteable.weight).not_to be_nil
                end
              }
            )
          ]
        end
      end

      context "with assignees quick actions" do
        let(:update_service) { Issues::UpdateService }
        let(:noteable_type) { 'Issue' }

        context "with a single line note" do
          let(:validation_message) { "Assignees total must be less than or equal to 2" }

          let(:note_text) do
            "/assign #{user1.to_reference} #{user2.to_reference} #{user3.to_reference}"
          end

          it_behaves_like 'does not exceed the issuable size limit'
        end

        context "with a multi line note" do
          let(:validation_message) { "Assignees total must be less than or equal to 2" }
          let(:note_text) do
            <<~HEREDOC
                  /assign #{user1.to_reference}
                  /assign #{user2.to_reference}
                  /assign #{user3.to_reference}
            HEREDOC
          end

          it_behaves_like 'does not exceed the issuable size limit'
        end
      end
    end

    context 'for merge_requests', feature_category: :code_review_workflow do
      let(:issuable) { create(:merge_request, project: project, source_project: project) }
      let(:developer) { create(:user) }
      let(:opts) { { noteable_type: 'MergeRequest', noteable_id: issuable.id } }

      it_behaves_like 'issuable quick actions' do
        let(:quick_actions) do
          [
            QuickAction.new(
              before_action: -> {
                project.add_developer(developer)
                issuable.update!(reviewers: [user])
              },

              action_text: "/reassign_reviewer #{developer.to_reference}",
              expectation: ->(issuable, can_use_quick_action) {
                expect(issuable.reviewers == [developer]).to eq(can_use_quick_action)
              }
            )
          ]
        end
      end

      context "with assignees quick actions" do
        let(:update_service) { MergeRequests::UpdateService }
        let(:noteable_type) { 'MergeRequest' }

        context "with a single line note" do
          let(:validation_message) { "Assignees total must be less than or equal to 2" }
          let(:note_text) do
            "/assign #{user1.to_reference} #{user2.to_reference} #{user3.to_reference}"
          end

          it_behaves_like 'does not exceed the issuable size limit'
        end

        context "with a multi line note" do
          let(:validation_message) { "Assignees total must be less than or equal to 2" }
          let(:note_text) do
            <<~HEREDOC
                  /assign #{user1.to_reference}
                  /assign #{user2.to_reference}
                  /assign #{user3.to_reference}
            HEREDOC
          end

          it_behaves_like 'does not exceed the issuable size limit'
        end
      end

      context "with reviewers quick actions" do
        let(:update_service) { MergeRequests::UpdateService }
        let(:noteable_type) { 'MergeRequest' }

        context "with a single line note" do
          let(:validation_message) { "Reviewers total must be less than or equal to 2" }

          let(:note_text) do
            "/assign_reviewer #{user1.to_reference} #{user2.to_reference} #{user3.to_reference}"
          end

          it_behaves_like 'does not exceed the issuable size limit'
        end

        context "with a multi line note" do
          let(:validation_message) { "Reviewers total must be less than or equal to 2" }
          let(:note_text) do
            <<~HEREDOC
              /assign_reviewer #{user1.to_reference}
              /assign_reviewer #{user2.to_reference}
              /assign_reviewer #{user3.to_reference}
            HEREDOC
          end

          it_behaves_like 'does not exceed the issuable size limit'
        end
      end
    end

    context 'for epics', feature_category: :portfolio_management do
      let_it_be(:epic) { create(:epic) }

      let(:opts) { { noteable_type: 'Epic', noteable_id: epic.id, note: "hello" } }

      it 'tracks epic note creation' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_note_created_action)
          .with(author: user, namespace: epic.group)

        described_class.new(nil, user, opts).execute
      end
    end
  end
end
