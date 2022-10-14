# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'as an orchestration policy' do
  let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, security_policy_management_project: policy_management_project, project: project) }
  let(:repository) { instance_double(Repository, root_ref: 'master', empty?: false) }

  describe '#resolve' do
    before do
      commit = create(:commit)
      commit.committed_date = policy_last_updated_at
      allow(policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).and_return(commit)
      allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'returns empty collection' do
        expect(resolve_scan_policies).to be_empty
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      it 'returns scan execution policies' do
        expect(resolve_scan_policies).to eq(expected_resolved)
      end

      context 'when user is unauthorized' do
        let(:user) { create(:user) }

        it 'returns empty collection' do
          expect(resolve_scan_policies).to be_empty
        end
      end
    end
  end
end
