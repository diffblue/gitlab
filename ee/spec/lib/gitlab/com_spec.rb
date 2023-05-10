# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Com, feature_category: :shared do
  it { expect(described_class.l1_cache_backend).to eq(Gitlab::ProcessMemoryCache.cache_backend) }
  it { expect(described_class.l2_cache_backend).to eq(Rails.cache) }

  describe '.gitlab_com_group_member?' do
    subject { described_class.gitlab_com_group_member?(user) }

    let(:user) { create(:user) }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      allow(Gitlab).to receive(:jh?).and_return(false)
    end

    context 'when user is a gitlab team member' do
      include_context 'gitlab team member'

      it { is_expected.to be true }

      describe 'caching of allowed user IDs' do
        before do
          described_class.gitlab_com_group_member?(user)
        end

        it_behaves_like 'allowed user IDs are cached'
      end

      context 'when not on Gitlab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it { is_expected.to be false }
      end

      context 'when on JiHu' do
        before do
          allow(Gitlab).to receive(:jh?).and_return(true)
        end

        it { is_expected.to be false }
      end
    end

    context 'when user is not a gitlab team member' do
      it { is_expected.to be false }

      describe 'caching of allowed user IDs' do
        before do
          described_class.gitlab_com_group_member?(user)
        end

        it_behaves_like 'allowed user IDs are cached'
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be false }
    end

    context 'when subject is not a user' do
      include_context 'gitlab team member'

      let(:user) { build_stubbed(:group_member, source: namespace) }

      it { is_expected.to be false }
    end

    context 'when gitlab-com group does not exist' do
      before do
        allow(Group).to receive(:find_by_name).and_return(nil)
      end

      it { is_expected.to be false }
    end
  end
end
