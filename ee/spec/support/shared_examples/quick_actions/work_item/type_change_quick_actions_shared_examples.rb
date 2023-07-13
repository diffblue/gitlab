# frozen_string_literal: true

RSpec.shared_examples 'quick actions that change work item type ee' do
  include_context 'with work item change type context'

  describe 'promote_to command' do
    let(:new_type) { 'objective' }
    let(:command) { "/promote_to #{new_type}" }

    context 'with key result' do
      let_it_be(:work_item) { create(:work_item, :key_result, project: project) }
      let(:with_access) { true }
      let(:new_type) { 'objective' }
      let(:command) { "/promote_to #{new_type}" }

      it 'populates :issue_type: and :work_item_type' do
        _, updates, message = service.execute(command, work_item)

        expect(message).to eq(_('Work item promoted successfully.'))
        expect(updates).to eq({ issue_type: 'objective', work_item_type: WorkItems::Type.default_by_type(:objective) })
      end

      context 'when new type is not supported' do
        let(:new_type) { 'task' }

        it_behaves_like 'quick command error', 'Provided type is not supported', 'promote'
      end

      context 'when user has insufficient permissions to create new type' do
        let(:with_access) { false }

        it_behaves_like 'quick command error', 'You have insufficient permissions', 'promote'
      end
    end
  end
end
