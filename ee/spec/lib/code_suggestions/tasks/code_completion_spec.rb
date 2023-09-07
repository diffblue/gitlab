# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeCompletion, feature_category: :code_suggestions do
  let(:prefix) { 'some text' }
  let(:params) { { 'current_file' => { 'file_name' => 'test.py', 'content_above_cursor' => prefix } } }

  it_behaves_like 'code suggestion task' do
    let(:task) { described_class.new(params) }
    let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/code/completions' }
    let(:body) { params.merge('prompt_version' => 1) }
  end
end
