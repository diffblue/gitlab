# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TargetBranchRules::DestroyService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:rule) { create(:target_branch_rule, project: project, name: 'feature', target_branch: 'other-branch') }
  let(:params) { { id: rule.id } }

  subject(:service) { described_class.new(project, user, params) }

  describe 'when the target_branch_rules_flag flag is disabled' do
    before do
      stub_feature_flags(target_branch_rules_flag: false)
    end

    it 'returns an error' do
      response = service.execute

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq(_('You have insufficient permissions to delete a target branch rule'))
    end
  end

  describe 'when the project does not have the correct license' do
    before do
      stub_licensed_features(target_branch_rules: false)
    end

    it 'returns an error' do
      response = service.execute

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq(_('You have insufficient permissions to delete a target branch rule'))
    end
  end

  describe 'when the user does not have permissions' do
    it 'returns an error' do
      response = service.execute

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq(_('You have insufficient permissions to delete a target branch rule'))
    end
  end

  context 'when user has permission' do
    before_all do
      project.add_owner(user)
    end

    before do
      stub_licensed_features(target_branch_rules: true)
    end

    describe 'when the target branch rule does not exist' do
      let_it_be(:params) { { id: non_existing_record_id } }

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Target branch rule does not exist')
      end
    end

    context 'when branch destroy fails' do
      it 'returns an error' do
        allow_next_found_instance_of(Projects::TargetBranchRule) do |branch|
          allow(branch).to receive(:destroy).and_return(false)
        end

        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Failed to delete target branch rule')
      end
    end

    describe 'when the target branch gets destroyed' do
      it 'returns success' do
        expect { expect(service.execute[:status]).to eq(:success) }
          .to change { project.target_branch_rules.count }.by(-1)
      end
    end
  end
end
