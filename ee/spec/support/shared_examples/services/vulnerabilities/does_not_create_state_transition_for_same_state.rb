# frozen_string_literal: true

RSpec.shared_examples 'does not create state transition for same state' do
  context 'when vulnerability state is not different from the requested state' do
    let(:vulnerability) { create(:vulnerability, state, :with_findings, project: project) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'does not create a state transition entry' do
        expect { action }.not_to change(Vulnerabilities::StateTransition, :count)
      end
    end
  end
end
