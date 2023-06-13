# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestionsAlertHelper, feature_category: :code_suggestions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { build_stubbed(:user) }

  describe '#show_code_suggestions_alert?' do
    where(
      feature_flag_enabled?: [true, false],
      cookie_present?: ['true', nil],
      check_namespace_plan?: [true, false],
      user?: [true, false],
      code_suggestions_enabled?: [true, false],
      nav_alert_dismissed: [true, false]
    )

    with_them do
      let(:local_user) { user? ? user : nil }

      before do
        stub_feature_flags(code_suggestions_alert: feature_flag_enabled?)
        stub_ee_application_setting(should_check_namespace_plan: check_namespace_plan?)
        helper.request.cookies['code_suggestions_alert_dismissed'] = cookie_present?
        allow(helper).to receive(:current_user) { local_user }
        allow(user).to receive(:code_suggestions_enabled?) { code_suggestions_enabled? }
        allow(helper).to receive(:user_dismissed_before?).and_return(nav_alert_dismissed)
      end

      let(:expected_result) do
        check_namespace_plan? &&
          !cookie_present? &&
          feature_flag_enabled? &&
          (local_user.nil? || (nav_alert_dismissed && !code_suggestions_enabled?))
      end

      subject { helper.show_code_suggestions_alert? }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#show_code_suggestions_third_party_alert?' do
    let_it_be(:group) { build_stubbed(:group) }

    where(
      check_namespace_plan?: [true, false],
      feature_flag_enabled?: [true, false],
      third_party_callout: [true, false],
      code_suggestions_enabled?: [true, false],
      code_suggestions: [true, false],
      third_party_ai_features_enabled: [true, false]
    )

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        stub_ee_application_setting(should_check_namespace_plan: check_namespace_plan?)
        stub_feature_flags(code_suggestions_third_party_alert: feature_flag_enabled?)
        allow(helper).to receive(:show_code_suggestions_third_party_callout?).and_return(third_party_callout)
        allow(user).to receive(:code_suggestions_enabled?) { code_suggestions_enabled? }
        allow(group).to receive(:code_suggestions) { code_suggestions }
        allow(group).to receive(:third_party_ai_features_enabled) { third_party_ai_features_enabled }
      end

      let(:expected_result) do
        check_namespace_plan? &&
          feature_flag_enabled? &&
          third_party_callout &&
          code_suggestions_enabled? &&
          code_suggestions &&
          third_party_ai_features_enabled
      end

      subject { helper.show_code_suggestions_third_party_alert?(group) }

      it { is_expected.to eq(expected_result) }
    end
  end
end
