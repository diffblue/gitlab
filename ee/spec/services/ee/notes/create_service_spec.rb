# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::CreateService do
  context 'note with commands' do
    let(:project) { create(:project) }
    let(:note_params) { opts }

    let_it_be(:user) { create(:user) }

    context 'for issues' do
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
    end

    context 'for merge_requests' do
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

      context "with reviewers quick actions" do
        RSpec.shared_examples 'does not exceed the reviewer size limit' do
          let(:reviewer1) { create(:user) }
          let(:reviewer2) { create(:user) }
          let(:reviewer3) { create(:user) }

          before do
            project.add_maintainer(user)
            project.add_maintainer(reviewer1)
            project.add_maintainer(reviewer2)
            project.add_maintainer(reviewer3)
          end

          context "number of reviewers does exceed the limit" do
            before do
              stub_const("MergeRequest::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS", 2)
            end

            it 'will not add more than the correct number of reviewers' do
              service = instance_double(MergeRequests::UpdateService)

              allow(MergeRequests::UpdateService).to receive(:new).and_return(service)
              expect(service).not_to receive(:execute)

              note = described_class.new(project, user, opts.merge(
                                                          note: note_text,
                                                          noteable_type: 'MergeRequest',
                                                          noteable_id: issuable.id,
                                                          confidential: false
                                                        )).execute

              expect(note.errors[:validation]).to match_array(["Reviewers total must be less than or equal to 2"])
            end
          end

          context "number of reviewers does not exceed the limit" do
            before do
              stub_const("MergeRequest::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS", 6)
            end

            it 'will not add more than the correct number of reviewers' do
              service = instance_double(MergeRequests::UpdateService)

              allow(MergeRequests::UpdateService).to receive(:new).and_return(service)
              expect(service).to receive(:execute)

              note = described_class.new(project, user, opts.merge(
                                                          note: note_text,
                                                          noteable_type: 'MergeRequest',
                                                          noteable_id: issuable.id,
                                                          confidential: false
                                                        )).execute

              expect(note.errors[:validation]).to be_empty
            end
          end
        end

        context "with a single line note" do
          it_behaves_like 'does not exceed the reviewer size limit' do
            let(:note_text) do
              "/assign_reviewer #{reviewer1.to_reference} #{reviewer2.to_reference} #{reviewer3.to_reference}"
            end
          end
        end

        context "with a multi line note" do
          it_behaves_like 'does not exceed the reviewer size limit' do
            let(:note_text) do
              <<~HEREDOC
              /assign_reviewer #{reviewer1.to_reference}
              /assign_reviewer #{reviewer2.to_reference}
              /assign_reviewer #{reviewer3.to_reference}
              HEREDOC
            end
          end
        end
      end
    end

    context 'for epics' do
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
