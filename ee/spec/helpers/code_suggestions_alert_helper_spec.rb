# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestionsAlertHelper, feature_category: :code_suggestions do
  let_it_be(:user) { build_stubbed(:user) }

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
