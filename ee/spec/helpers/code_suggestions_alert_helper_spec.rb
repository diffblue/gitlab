# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestionsAlertHelper, feature_category: :code_suggestions do
  describe '#show_code_suggestions_alert?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { build_stubbed(:user) }

    where(
      feature_flag_enabled?: [true, false],
      cookie_present?: ['true', nil],
      check_namespace_plan?: [true, false],
      user?: [true, false],
      code_suggestions_enabled?: [true, false]
    )

    with_them do
      let(:local_user) { user? ? user : nil }

      before do
        stub_feature_flags(code_suggestions_alert: feature_flag_enabled?)
        stub_ee_application_setting(should_check_namespace_plan: check_namespace_plan?)
        helper.request.cookies['code_suggestions_alert_dismissed'] = cookie_present?
        allow(helper).to receive(:current_user) { local_user }
        allow(user).to receive(:code_suggestions_enabled?) { code_suggestions_enabled? }
      end

      let(:expected_result) do
        check_namespace_plan? &&
          !cookie_present? &&
          feature_flag_enabled? &&
          (local_user.nil? || !code_suggestions_enabled?)
      end

      subject { helper.show_code_suggestions_alert? }

      it { is_expected.to eq(expected_result) }
    end
  end
end
