# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetIteration do
  let_it_be(:cadence) { create(:iterations_cadence) }

  let(:issue) { create(:issue) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let(:iteration) { create(:iteration, iterations_cadence: cadence) }
    let(:mutated_issue) { subject[:issue] }

    subject { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, iteration: iteration) }

    it_behaves_like 'permission level for issue mutation is correctly verified'

    context 'when the user can update the issue' do
      before do
        issue.project.add_developer(user)
      end

      it 'returns the issue with the iteration' do
        expect(mutated_issue).to eq(issue)
        expect(mutated_issue.iteration).to eq(iteration)
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors issue could not be updated' do
        # Make the issue invalid
        issue.update_column(:author_id, nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing iteration_id as nil' do
        let(:iteration) { nil }

        it 'removes the iteration' do
          issue.update!(iteration: create(:iteration, iterations_cadence: cadence))

          expect(mutated_issue.iteration).to eq(nil)
        end

        it 'does not do anything if the issue already does not have a iteration' do
          expect(mutated_issue.iteration).to eq(nil)
        end
      end
    end
  end
end
