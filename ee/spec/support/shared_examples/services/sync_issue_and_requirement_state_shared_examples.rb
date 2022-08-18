# frozen_string_literal: true

RSpec.shared_examples 'sync requirement with issue state' do
  let_it_be(:not_member) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  let(:issue) { create(:issue, issue_type: :requirement, project: project, state: issue_initial_state) }
  let!(:requirement) { create(:requirement, project: project, requirement_issue: issue, state: requirement_initial_state) }

  subject { described_class.new(project: project, current_user: not_member).execute(issue, skip_authorization: skip_authorization) }

  context 'when skip_authorization is false' do
    let(:skip_authorization) { false }

    it 'does not change issue state' do
      subject

      expect(issue.reload.state).to eq(issue_initial_state)
      expect(requirement.reload.state).to eq(requirement_initial_state)
    end
  end

  context 'when skip_authorization is true' do
    let(:skip_authorization) { true }

    context 'when issue is not of requirement_type' do
      before do
        issue.update!(issue_type: :incident)
      end

      it 'does not sync state' do
        subject

        expect(issue.reload.state).to eq(issue_expected_state)
        expect(requirement.reload.state).to be_nil
      end
    end

    it 'keeps requirement and requirement issue in sync' do
      subject

      expect(issue.reload.state).to eq(issue_expected_state)
      expect(requirement.reload.state).to eq(requirement_expected_state)
    end

    context 'when saving requirement fails' do
      before do
        allow(issue).to receive(:requirement).and_return(requirement)
        allow(requirement).to receive(:save!).and_raise(ActiveRecord::StatementTimeout, 'time is out')
      end

      it 'does not change requirement and issue states' do
        subject

        expect(issue.reload.state).to eq(issue_initial_state)
        expect(requirement.reload.state).to eq(requirement_initial_state)
      end

      it 'logs error' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: 'Requirement-Issue state Sync: Associated requirement could not be saved',
          error: 'time is out',
          project_id: project.id,
          user_id: not_member.id,
          requirement_id: requirement.id,
          issue_id: issue.id,
          state: requirement_expected_state
        )

        subject
      end
    end
  end
end
