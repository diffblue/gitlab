# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Prompts::CodeGeneration::VertexAi, feature_category: :code_suggestions do
  let(:prefix) { 'prefix' }
  let(:filename) { 'test.py' }
  let(:params) do
    {
      instruction: 'create something',
      prefix: prefix,
      current_file: {
        file_name: filename
      }
    }
  end

  subject { described_class.new(params) }

  it_behaves_like 'code suggestion prompt' do
    let(:request_params) do
      {
        prompt_version: 2,
        prompt: <<~PROMPT
        This is a task to write new Python code in a file 'test.py' based on a given description.
        You get first the already existing code file and then the description of the code that needs to be created.
        It is your task to write valid and working Python code.
        Only return in your response new code.

        Already existing code:

        ```py
        prefix
        ```

        Create new code for the following description:
        `create something`
        PROMPT
      }
    end
  end

  context 'when prefix is missing' do
    let(:prefix) { '' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          prompt_version: 2,
          prompt: <<~PROMPT
            This is a task to write new Python code in a file 'test.py' based on a given description.

            It is your task to write valid and working Python code.
            Only return in your response new code.

            Create new code for the following description:
            `create something`
          PROMPT
        }
      end
    end
  end

  context 'when filename is missing' do
    let(:filename) { '' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          prompt_version: 2,
          prompt: <<~PROMPT
            This is a task to write new  code in a file '' based on a given description.
            You get first the already existing code file and then the description of the code that needs to be created.
            It is your task to write valid and working  code.
            Only return in your response new code.

            Already existing code:

            ```
            prefix
            ```

            Create new code for the following description:
            `create something`
          PROMPT
        }
      end
    end
  end

  context 'when language is not supported' do
    let(:filename) { 'test.foo' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          prompt_version: 2,
          prompt: <<~PROMPT
            This is a task to write new  code in a file 'test.foo' based on a given description.
            You get first the already existing code file and then the description of the code that needs to be created.
            It is your task to write valid and working  code.
            Only return in your response new code.

            Already existing code:

            ```foo
            prefix
            ```

            Create new code for the following description:
            `create something`
          PROMPT
        }
      end
    end
  end
end
