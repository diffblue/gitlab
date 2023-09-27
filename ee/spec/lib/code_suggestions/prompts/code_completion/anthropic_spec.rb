# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Prompts::CodeCompletion::Anthropic, feature_category: :code_suggestions do
  let(:prefix) { 'prefix' }
  let(:suffix) { 'suffix' }
  let(:filename) { 'test.py' }
  let(:params) do
    {
      current_file: {
        file_name: filename,
        content_above_cursor: prefix,
        content_below_cursor: suffix
      }
    }
  end

  subject { described_class.new(params) }

  it_behaves_like 'code suggestion prompt' do
    let(:request_params) do
      {
        prompt_version: 2,
        prompt: <<~PROMPT
          Human: Here is a content of a file 'test.py' written in Python enclosed
          in <code></code> tags. Review the code to understand existing logic and format, then return
          a valid code enclosed in <result></result> tags which can be added instead of
          <complete> tag. Do not add other code.

          <code>
            prefix<complete>
            suffix
          </code>

          Assistant:
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
            Human: Here is a content of a file 'test.py' written in Python enclosed
            in <code></code> tags. Review the code to understand existing logic and format, then return
            a valid code enclosed in <result></result> tags which can be added instead of
            <complete> tag. Do not add other code.

            <code>
              <complete>
              suffix
            </code>

            Assistant:
          PROMPT
        }
      end
    end
  end

  context 'when suffix is missing' do
    let(:suffix) { '' }

    it_behaves_like 'code suggestion prompt' do
      let(:request_params) do
        {
          prompt_version: 2,
          prompt: <<~PROMPT
            Human: Here is a content of a file 'test.py' written in Python enclosed
            in <code></code> tags. Review the code to understand existing logic and format, then return
            a valid code enclosed in <result></result> tags which can be added instead of
            <complete> tag. Do not add other code.

            <code>
              prefix<complete>\n  \n</code>

            Assistant:
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
            Human: Here is a content of a file '' written in  enclosed
            in <code></code> tags. Review the code to understand existing logic and format, then return
            a valid code enclosed in <result></result> tags which can be added instead of
            <complete> tag. Do not add other code.

            <code>
              prefix<complete>
              suffix
            </code>

            Assistant:
          PROMPT
        }
      end
    end
  end
end
