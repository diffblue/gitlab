# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreferencesHelper do
  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  let(:user) { build(:user) }

  describe '#dashboard_choices' do
    context 'when allowed to read operations dashboard' do
      before do
        allow(helper).to receive(:can?).with(user, :read_operations_dashboard) { true }
      end

      it 'does not contain operations dashboard' do
        expect(helper.dashboard_choices).to include({ text: 'Operations Dashboard', value: 'operations' })
      end
    end

    context 'when not allowed to read operations dashboard' do
      before do
        allow(helper).to receive(:can?).with(user, :read_operations_dashboard) { false }
      end

      it 'does not contain operations dashboard' do
        expect(helper.dashboard_choices).not_to include(['Operations Dashboard', 'operations'])
      end
    end
  end

  describe '#group_view_choices' do
    subject { helper.group_view_choices }

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it { is_expected.to include(['Security dashboard', :security_dashboard]) }
    end

    context 'when security dashboard feature is disabled' do
      it { is_expected.not_to include(['Security dashboard', :security_dashboard]) }
    end
  end

  describe '#group_overview_content_preference?' do
    subject { helper.group_overview_content_preference? }

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when security dashboard feature is disabled' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#should_show_code_suggestions_preferences?' do
    subject { helper.should_show_code_suggestions_preferences?(user) }

    let(:user) { create_default(:user) }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(enable_hamilton_in_user_preferences: false)
      end

      it { is_expected.to eq(false) }
    end

    it { is_expected.to eq(true) }
  end
end
