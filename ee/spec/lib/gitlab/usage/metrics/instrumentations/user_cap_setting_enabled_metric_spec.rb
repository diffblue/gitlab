# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Usage::Metrics::Instrumentations::UserCapSettingEnabledMetric do
  using RSpec::Parameterized::TableSyntax

  where(:user_cap_feature_enabled, :expected_value) do
    42 | 42
    -1 | -1
  end

  with_them do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      stub_application_setting(new_user_signups_cap: user_cap_feature_enabled)
    end

    it_behaves_like 'a correct instrumented metric value', {}
  end
end
