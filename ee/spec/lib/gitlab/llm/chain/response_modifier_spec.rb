# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::ResponseModifier, feature_category: :shared do
  let(:content) { "This is the summary" }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:status) { :ok }
  let(:answer) do
    ::Gitlab::Llm::Chain::Answer.new(
      status: status, context: context, content: content, tool: nil, is_final: true
    )
  end

  context 'on success' do
    subject { described_class.new(answer).response_body }

    it { is_expected.to eq content }
  end

  context 'on error' do
    let(:status) { :error }

    subject { described_class.new(answer).errors }

    it { is_expected.to eq [content] }
  end
end
