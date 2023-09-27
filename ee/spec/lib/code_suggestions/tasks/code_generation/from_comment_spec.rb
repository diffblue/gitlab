# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeGeneration::FromComment, feature_category: :code_suggestions do
  let(:unsafe_params) do
    {
      'current_file' => {
        'file_name' => 'test.py',
        'content_above_cursor' => 'some text'
      },
      'telemetry' => [{ 'model_engine' => 'vertex-ai' }]
    }
  end

  let(:task) { described_class.new(params: {}, unsafe_passthrough_params: unsafe_params) }
  let(:request_params) { { prompt_version: 1, prompt: 'foo' } }

  before do
    allow_next_instance_of(CodeSuggestions::Prompts::CodeGeneration::VertexAi) do |prompt|
      allow(prompt).to receive(:request_params).and_return(request_params)
    end
  end

  it_behaves_like 'code suggestion task' do
    let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/code/generations' }
    let(:body) { unsafe_params.merge(request_params.stringify_keys) }
  end
end
