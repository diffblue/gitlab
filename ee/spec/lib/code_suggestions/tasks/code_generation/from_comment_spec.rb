# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeGeneration::FromComment, feature_category: :code_suggestions do
  let(:prefix) { 'some text' }
  let(:params) { { 'current_file' => { 'file_name' => 'test.py', 'content_above_cursor' => prefix } } }

  it_behaves_like 'code suggestion task' do
    let(:task) { described_class.new(params) }
    let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/code/generations' }
    let(:body) { params.merge('prompt' => "```py\nsome text\n```\n", 'prompt_version' => 2) }
  end
end
