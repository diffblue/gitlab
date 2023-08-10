# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TargetBranchRules::CreateService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let(:params) { { name: 'dev/*', target_branch: 'main' } }

  subject(:service) { described_class.new(project, user, params) }

  describe 'when the target_branch_rules_flag flag is disabled' do
    before do
      stub_feature_flags(target_branch_rules_flag: false)
    end

    it 'returns an error' do
      response = service.execute

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq(_('You have insufficient permissions to create a target branch rule'))
    end
  end

  describe 'when the project does not have the correct license' do
    before do
      stub_licensed_features(target_branch_rules: false)
    end

    it 'returns an error' do
      response = service.execute

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq(_('You have insufficient permissions to create a target branch rule'))
    end
  end

  describe 'when the user does not have permissions' do
    it 'returns an error' do
      response = service.execute

      expect(response[:status]).to eq(:error)
      expect(response[:message]).to eq(_('You have insufficient permissions to create a target branch rule'))
    end
  end

  context 'when user has permission' do
    before_all do
      project.add_owner(user)
    end

    before do
      stub_licensed_features(target_branch_rules: true)
    end

    describe 'when the target branch rule already exists' do
      before do
        create(:target_branch_rule, project: project, name: 'dev/*')
      end

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to contain_exactly('Name has already been taken')
      end
    end

    describe 'when the target branch gets created' do
      it 'returns success' do
        expect { expect(service.execute[:status]).to eq(:success) }
          .to change { project.target_branch_rules.count }.by(1)
      end
    end
  end
end
