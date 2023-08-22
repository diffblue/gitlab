# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::ToolResponseModifier, feature_category: :shared do
  let(:content) { ::Gitlab::Llm::Chain::Tools::GitlabDocumentation::Executor }

  context 'on success' do
    subject { described_class.new(content).response_body }

    it { is_expected.to eq content::HUMAN_NAME }
  end

  context 'on error' do
    subject { described_class.new(content).errors }

    it { is_expected.to eq [] }
  end
end
