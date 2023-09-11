# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::TaskSelector, feature_category: :code_suggestions do
  using RSpec::Parameterized::TableSyntax

  let(:params) { { 'current_file' => { 'content_above_cursor' => prefix } } }

  describe '.task' do
    subject { described_class.task(params: params) }

    context 'with the prefix, suffix produces the correct type' do
      where(:prefix, :type) do
        # rubocop:disable Layout/LineLength
        # Standard code generation comments
        "# GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
        '// GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers' | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "#GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
        '//GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers'  | CodeSuggestions::Tasks::CodeGeneration::FromComment

        # Line breaks at the end of the comment
        "# GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "// GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n" | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "#GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "//GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n"  | CodeSuggestions::Tasks::CodeGeneration::FromComment

        # These have characters _before_ the comment
        "end\n\n# GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"    | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "}\n\n\n\n// GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "    #GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"        | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "   \r\n   //GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment

        # These rely on case-insensitivity
        "# GitLab duo generate: A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
        '// gitLab Duo Generate: A function that outputs the first 20 fibonacci numbers' | CodeSuggestions::Tasks::CodeGeneration::FromComment
        "#gitLab Duo generate: A function that outputs the first 20 fibonacci numbers"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
        '//gitLab duo generate: A function that outputs the first 20 fibonacci numbers'  | CodeSuggestions::Tasks::CodeGeneration::FromComment

        # These are too short to be considered generation
        "# GitLab Duo Generate: A func" | CodeSuggestions::Tasks::CodeCompletion
        '// GitLab Duo Generate: A fun' | CodeSuggestions::Tasks::CodeCompletion
        "#GitLab Duo Generate: A func"  | CodeSuggestions::Tasks::CodeCompletion
        '//GitLab Duo Generate: A fu'   | CodeSuggestions::Tasks::CodeCompletion

        # These include no comments at all
        'def fibonacci(i)'        | CodeSuggestions::Tasks::CodeCompletion
        'function fibonacci(x) {' | CodeSuggestions::Tasks::CodeCompletion
        # rubocop:enable Layout/LineLength
      end

      with_them do
        it { is_expected.to be_an_instance_of(type) }
      end
    end

    context 'when the last comment is a code generation' do
      let(:prefix) do
        <<~TEXT
          # GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers
          def fibonacci(x)

          # GitLab Duo Generate: A function that rounds every number to the nearest 10
        TEXT
      end

      it 'only takes the last example in to account' do
        expect(subject).to be_an_instance_of(CodeSuggestions::Tasks::CodeGeneration::FromComment)
      end

      context 'when prefix is too long' do
        before do
          stub_const('CodeSuggestions::TaskSelector::PREFIX_MAX_SIZE', 10)
        end

        it 'does not parse prefix and uses completion' do
          expect(subject).to be_an_instance_of(CodeSuggestions::Tasks::CodeCompletion)
        end
      end
    end

    context 'when the last comment is a code suggestion' do
      let(:prefix) do
        <<~TEXT
          # GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers

          def fibonacci(x)

        TEXT
      end

      it 'only takes the last example in to account' do
        expect(subject).to be_an_instance_of(CodeSuggestions::Tasks::CodeCompletion)
      end
    end
  end
end
