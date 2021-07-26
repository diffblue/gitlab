# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetEpic do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:issue) { create(:issue, project: project) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be_with_reload(:epic) { create(:epic, group: group) }

    let(:mutated_issue) { subject[:issue] }

    subject { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, epic: epic) }

    it_behaves_like 'permission level for issue mutation is correctly verified', true

    context 'when the user can update the issue' do
      before do
        stub_licensed_features(epics: true)
        project.add_guest(user)
      end

      it 'raises an error if the epic is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end

      context 'when user can admin epic' do
        before do
          group.add_owner(user)
        end

        it 'returns the issue with the epic' do
          expect(mutated_issue).to eq(issue)
          expect(mutated_issue.epic).to eq(epic)
          expect(subject[:errors]).to be_empty
        end

        it 'returns errors if issue could not be updated' do
          issue.update_column(:author_id, nil)

          expect(subject[:errors]).to eq(["Author can't be blank"])
        end

        context 'when passing epic_id as nil' do
          let(:epic) { nil }

          it 'removes the epic' do
            issue.update!(epic: create(:epic, group: group))

            expect(mutated_issue.epic).to eq(nil)
          end

          it 'does not do anything if the issue already does not have a epic' do
            expect(mutated_issue.epic).to eq(nil)
          end
        end

        context 'when epic is confidential but issue is public' do
          let(:epic) { create(:epic, group: group, confidential: true) }

          it 'returns an error with appropriate message' do
            expect(subject[:errors].first).to include("Cannot assign a confidential epic to a non-confidential issue. Make the issue confidential and try again")
          end
        end
      end
    end
  end
end
