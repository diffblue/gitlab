# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Preview, :saas do
  let_it_be(:namespace) { create(:group_with_plan, :private, plan: :free_plan) }

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
    allow(namespace).to receive(:free_plan_members_count).and_return(Namespaces::FreeUserCap.dashboard_limit + 1)
  end

  describe '#over_limit?' do
    subject(:over_limit?) { described_class.new(namespace).over_limit? }

    context 'when :preview_free_user_cap is disabled' do
      before do
        stub_feature_flags(preview_free_user_cap: false)
      end

      it { is_expected.to be false }
    end

    context 'when :preview_free_user_cap is enabled' do
      it { is_expected.to be true }

      context 'when the namespace is public' do
        before do
          namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it { is_expected.to be false }
      end
    end
  end
end
