# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Logger, feature_category: :ai_abstraction_layer do
  describe "log_level" do
    subject(:log_level) { described_class.build.level }

    context 'when LLM_DEBUG is not set' do
      it { is_expected.to eq ::Logger::INFO }
    end

    context 'when LLM_DEBUG=true' do
      before do
        stub_env('LLM_DEBUG', true)
      end

      it { is_expected.to eq ::Logger::DEBUG }
    end

    context 'when LLM_DEBUG=false' do
      before do
        stub_env('LLM_DEBUG', false)
      end

      it { is_expected.to eq ::Logger::INFO }
    end
  end
end
