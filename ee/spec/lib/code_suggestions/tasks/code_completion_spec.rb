# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeCompletion, feature_category: :code_suggestions do
  let(:request_params) { { prompt_version: 10, prompt: 'foo' } }
  let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/code/completions' }

  let(:unsafe_params) do
    {
      'current_file' => {
        'file_name' => 'test.py',
        'content_above_cursor' => 'some text'
      },
      'telemetry' => [{ 'model_engine' => 'vertex-ai' }]
    }
  end

  let(:params) do
    {
      model_family: model_family
    }
  end

  let(:task) { described_class.new(params: params, unsafe_passthrough_params: unsafe_params) }

  context 'when using Vertex' do
    let(:model_family) { :vertex_ai }

    before do
      allow_next_instance_of(CodeSuggestions::Prompts::CodeCompletion::VertexAi) do |prompt|
        allow(prompt).to receive(:request_params).and_return(request_params)
      end
    end

    it_behaves_like 'code suggestion task' do
      let(:body) { unsafe_params.merge(request_params.stringify_keys) }
    end
  end

  context 'when using Anthropic' do
    let(:model_family) { :anthropic }

    before do
      allow_next_instance_of(CodeSuggestions::Prompts::CodeCompletion::Anthropic) do |prompt|
        allow(prompt).to receive(:request_params).and_return(request_params)
      end
    end

    it_behaves_like 'code suggestion task' do
      let(:body) { unsafe_params.merge(request_params.stringify_keys) }
    end
  end
end
