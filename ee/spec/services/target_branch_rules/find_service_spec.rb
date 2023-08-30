# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TargetBranchRules::FindService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  subject(:finder) { described_class.new(project, user) }

  before_all do
    create(:target_branch_rule, project: project, name: 'dev/*', target_branch: 'dev-target')
  end

  describe 'when the target_branch_rules_flag flag is disabled' do
    before do
      stub_feature_flags(target_branch_rules_flag: false)
    end

    it 'returns default branch' do
      expect(finder.execute('dev/testing')).to eq('master')
    end
  end

  describe 'when the project does not have the correct license' do
    before do
      stub_licensed_features(target_branch_rules: false)
    end

    it 'returns default branch' do
      expect(finder.execute('dev/testing')).to eq('master')
    end
  end

  describe 'when the user does not have permissions' do
    it 'returns default branch' do
      expect(finder.execute('dev/testing')).to eq('master')
    end
  end

  context 'when user has permission' do
    before_all do
      project.add_owner(user)
    end

    before do
      stub_licensed_features(target_branch_rules: true)
    end

    describe 'when the target branch rule does not exists' do
      it 'retuns success' do
        expect(finder.execute('hotfix/testing')).to eq('master')
      end
    end

    describe 'when the target branch rule exists' do
      it 'retuns success' do
        expect(finder.execute('dev/testing')).to eq('dev-target')
      end
    end
  end
end
