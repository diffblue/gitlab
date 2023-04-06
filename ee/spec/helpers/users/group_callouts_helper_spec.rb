# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GroupCalloutsHelper, feature_category: :subgroups do
  describe '#show_unlimited_members_during_trial_alert?' do
    let_it_be(:group) { build(:group, :private, name: 'private namespace') }
    let_it_be(:user) { build(:user) }
    let(:mock_enforcement) { instance_double(::Namespaces::FreeUserCap::Enforcement) }

    subject(:subject) { helper.show_unlimited_members_during_trial_alert?(group) }

    before do
      allow(::Namespaces::FreeUserCap::Enforcement).to receive(:new).and_return(mock_enforcement)
      allow(mock_enforcement).to receive(:qualified_namespace?).and_return(true)
      allow(::Namespaces::FreeUserCap).to receive(:owner_access?).and_return(true)
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:user_dismissed_for_group).and_return(false)
      allow(group).to receive(:trial_active?).and_return(true)
    end

    context 'when alert can be shown' do
      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when alert is dismissed' do
      before do
        allow(helper).to receive(:user_dismissed_for_group).and_return(true)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when user is not group owner' do
      before do
        allow(::Namespaces::FreeUserCap).to receive(:owner_access?).and_return(false)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when namespace is not qualified to see alert' do
      before do
        allow(mock_enforcement).to receive(:qualified_namespace?).and_return(false)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when namespace is not on a trial' do
      before do
        allow(group).to receive(:trial_active?).and_return(false)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end
end
