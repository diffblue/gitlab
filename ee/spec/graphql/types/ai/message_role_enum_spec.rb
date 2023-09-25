# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiMessageRole'], feature_category: :duo_chat do
  let(:expected_values) { %w[USER ASSISTANT SYSTEM] }

  subject { described_class.values.keys }

  it { is_expected.to contain_exactly(*expected_values) }
end
