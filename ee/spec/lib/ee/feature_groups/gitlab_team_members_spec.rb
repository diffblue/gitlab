# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureGroups::GitlabTeamMembers, feature_category: :shared do
  let(:group) { instance_double('Group') }
  let(:user) { build_stubbed(:user) }

  describe '#enabled?' do
    it 'returns false when actor is not a user' do
      expect(described_class.enabled?(group)).to eq(false)
    end

    context 'when actor is a user' do
      subject(:enabled?) { described_class.enabled?(user) }

      it 'returns true :Gitlab::Com.gitlab_com_group_member? returns true' do
        expect(Gitlab::Com).to receive(:gitlab_com_group_member?).with(user.id).and_return(true)

        expect(enabled?).to eq(true)
      end

      it 'returns false :Gitlab::Com.gitlab_com_group_member? returns false' do
        expect(Gitlab::Com).to receive(:gitlab_com_group_member?).with(user.id).and_return(false)

        expect(enabled?).to eq(false)
      end
    end
  end
end
