# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Preview, :saas do
  let_it_be(:namespace) { create(:group_with_plan, plan: :free_plan) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    allow(namespace).to receive(:free_plan_members_count).and_return(Namespaces::FreeUserCap::FREE_USER_LIMIT + 1)
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
    end
  end
end
