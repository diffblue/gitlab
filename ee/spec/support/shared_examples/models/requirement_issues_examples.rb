# frozen_string_literal: true

RSpec.shared_examples 'a model with a requirement issue association' do
  describe 'requirement issue association' do
    subject do
      requirement = build(:work_item, :requirement, project: requirement_issue_arg.project).requirement
      requirement.requirement_issue = requirement_issue_arg

      requirement
    end

    let(:requirement_issue) { build(:requirement_issue) }

    context 'when the requirement issue is of type requirement' do
      let(:requirement_issue_arg) { requirement_issue }

      specify { expect(subject).to be_valid }
    end

    context 'when requirement issue is not of requirement type' do
      let(:invalid_issue) { create(:issue) }
      let(:requirement_issue_arg) { invalid_issue }

      specify do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:requirement_issue]).to include(/must be a `requirement`/)
      end

      context 'when requirement issue is invalid but the type field is not dirty' do
        let(:requirement_arg) { nil }
        let(:requirement_issue_arg) { requirement_issue }

        before do
          subject.save!

          # simulate the issue type changing in the background, which will be allowed
          # the state is technically "invalid" (there are test reports associated with a non-requirement issue)
          # but we don't want to prevent updating other fields
          requirement_issue.update_columns(
            issue_type: :incident,
            work_item_type_id: WorkItems::Type.default_by_type(:incident).id
          )
        end

        specify do
          expect(subject).to be_valid
        end

        it { is_expected.to be_valid }
      end
    end
  end
end
