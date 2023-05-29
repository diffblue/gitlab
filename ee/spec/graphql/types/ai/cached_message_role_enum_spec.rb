# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiCachedMessageRole'], feature_category: :shared do
  let(:expected_values) { %w[USER ASSISTANT] }

  subject { described_class.values.keys }

  it { is_expected.to contain_exactly(*expected_values) }
end
