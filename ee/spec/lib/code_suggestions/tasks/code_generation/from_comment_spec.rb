# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeGeneration::FromComment, feature_category: :code_suggestions do
  let(:prefix) { 'some text' }
  let(:instruction) { 'Add code for validating function' }

  let(:params) do
    {
      :prefix => prefix,
      :instruction => instruction,
      'current_file' => {
        'file_name' => 'test.py',
        'content_above_cursor' => 'some text'
      }
    }
  end

  let(:prompt) do
    <<~PROMPT
      This is a task to write new Python code in a file 'test.py' based on a given description.
      You get first the already existing code file and then the description of the code that needs to be created.
      It is your task to write valid and working Python code.
      Only return in your response new code.

      Already existing code:

      ```py
      some text
      ```

      Create new code for the following description:
      `#{instruction}`
    PROMPT
  end

  it_behaves_like 'code suggestion task' do
    let(:task) { described_class.new(params) }
    let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/code/generations' }
    let(:body) do
      params.merge(
        'prompt' => prompt,
        'prompt_version' => 2
      )
    end
  end
end
