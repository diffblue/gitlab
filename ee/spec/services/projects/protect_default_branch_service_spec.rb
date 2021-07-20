# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProtectDefaultBranchService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project) }

  shared_context 'has security_policy_project' do
    before do
      allow(Security::OrchestrationPolicyConfiguration)
        .to receive(:exists?)
              .and_return(true)
    end
  end

  describe '#protect_branch?' do
    context 'when project has security_policy_project' do
      include_context 'has security_policy_project'

      it 'returns true' do
        expect(service.protect_branch?).to eq(true)
      end
    end

    it { expect(service.protect_branch?).to eq(false) }
  end

  describe '#push_access_level' do
    context 'when project has security_policy_project' do
      include_context 'has security_policy_project'

      it 'returns NO_ACCESS access level' do
        expect(service.push_access_level).to eq(Gitlab::Access::NO_ACCESS)
      end
    end

    context 'when project does not have security_policy_project' do
      before do
        allow(project.namespace)
          .to receive(:default_branch_protection)
                .and_return(Gitlab::Access::PROTECTION_DEV_CAN_PUSH)
      end

      it 'returns DEVELOPER access level' do
        expect(service.push_access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end
  end

  describe '#merge_access_level' do
    context 'when project has security_policy_project' do
      include_context 'has security_policy_project'

      it 'returns Maintainer access level' do
        expect(service.merge_access_level).to eq(Gitlab::Access::MAINTAINER)
      end
    end

    context 'when project does not have security_policy_project' do
      before do
        allow(project.namespace)
          .to receive(:default_branch_protection)
                .and_return(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
      end

      it 'returns DEVELOPER access level' do
        expect(service.merge_access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end
  end
end
