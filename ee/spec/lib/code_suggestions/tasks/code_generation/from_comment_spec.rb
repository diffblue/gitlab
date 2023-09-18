# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::CodeGeneration::FromComment, feature_category: :code_suggestions do
  let(:prefix) { 'some text' }
  let(:instruction) { 'Add code for validating function' }
  let(:file_name) { 'test.py' }

  let(:unsafe_params) do
    {
      'current_file' => {
        'file_name' => file_name,
        'content_above_cursor' => 'some text'
      },
      'telemetry' => [{ 'model_engine' => 'vertex-ai' }]
    }
  end

  let(:params) do
    {
      prefix: prefix,
      instruction: instruction,
      current_file: unsafe_params['current_file'].with_indifferent_access
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

  describe 'prompt build' do
    let(:task) { described_class.new(params: params, unsafe_passthrough_params: unsafe_params) }
    let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/code/generations' }
    let(:body) do
      unsafe_params.merge(
        'prompt' => prompt,
        'prompt_version' => 2
      )
    end

    it_behaves_like 'code suggestion task'

    context 'when there is no filename extension' do
      let(:file_name) { 'README' }
      let(:prompt) do
        <<~PROMPT
          This is a task to write new  code in a file 'README' based on a given description.
          You get first the already existing code file and then the description of the code that needs to be created.
          It is your task to write valid and working  code.
          Only return in your response new code.

          Already existing code:

          ```
          some text
          ```

          Create new code for the following description:
          `#{instruction}`
        PROMPT
      end

      it_behaves_like 'code suggestion task'
    end

    context 'when there is no prefix' do
      let(:prefix) { '' }
      let(:prompt) do
        <<~PROMPT
          This is a task to write new Python code in a file 'test.py' based on a given description.

          It is your task to write valid and working Python code.
          Only return in your response new code.

          Create new code for the following description:
          `#{instruction}`
        PROMPT
      end

      it_behaves_like 'code suggestion task'
    end
  end
end
