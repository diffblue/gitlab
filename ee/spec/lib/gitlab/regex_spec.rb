# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Regex do
  describe '.feature_flag_regex' do
    subject { described_class.feature_flag_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('f_feature_flag') }
    it { is_expected.not_to match('MY_FEATURE_FLAG') }
    it { is_expected.not_to match('my feature flag') }
    it { is_expected.not_to match('!!()()') }
  end
end
