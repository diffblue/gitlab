# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::TaskSelector, feature_category: :code_suggestions do
  using RSpec::Parameterized::TableSyntax

  let(:params) { { 'current_file' => { 'content_above_cursor' => prefix } } }

  describe '.task' do
    shared_examples 'correct task detector' do
      context 'with the prefix, suffix produces the correct type' do
        where(:prefix, :type) do
          # rubocop:disable Layout/LineLength
          # Standard code generation comments
          "# #{generate_prefix}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "// #{generate_prefix}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "##{generate_prefix}A function that outputs the first 20 fibonacci numbers"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "//#{generate_prefix}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # Line breaks at the end of the comment
          "# #{generate_prefix}A function that outputs the first 20 fibonacci numbers\n"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "// #{generate_prefix}A function that outputs the first 20 fibonacci numbers\n" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "##{generate_prefix}A function that outputs the first 20 fibonacci numbers\n"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "//#{generate_prefix}A function that outputs the first 20 fibonacci numbers\n"  | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # These have characters _before_ the comment
          "end\n\n# #{generate_prefix}A function that outputs the first 20 fibonacci numbers"    | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "}\n\n\n\n// #{generate_prefix}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "    ##{generate_prefix}A function that outputs the first 20 fibonacci numbers"        | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "   \r\n   //#{generate_prefix}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # These rely on case-insensitivity
          "# #{case_insensitive_prefixes[0]}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "// #{case_insensitive_prefixes[1]}A function that outputs the first 20 fibonacci numbers" | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "##{case_insensitive_prefixes[2]}A function that outputs the first 20 fibonacci numbers"   | CodeSuggestions::Tasks::CodeGeneration::FromComment
          "//#{case_insensitive_prefixes[3]}A function that outputs the first 20 fibonacci numbers"  | CodeSuggestions::Tasks::CodeGeneration::FromComment

          # These are too short to be considered generation
          "# #{generate_prefix}A func" | CodeSuggestions::Tasks::CodeCompletion
          "// #{generate_prefix}A fun" | CodeSuggestions::Tasks::CodeCompletion
          "##{generate_prefix}A func"  | CodeSuggestions::Tasks::CodeCompletion
          "//#{generate_prefix}A fu"   | CodeSuggestions::Tasks::CodeCompletion

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
            # #{generate_prefix}A function that outputs the first 20 fibonacci numbers
            def fibonacci(x)

            # #{generate_prefix}A function that rounds every number to the nearest 10
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
            # #{generate_prefix}A function that outputs the first 20 fibonacci numbers

            def fibonacci(x)

          TEXT
        end

        it 'only takes the last example in to account' do
          expect(subject).to be_an_instance_of(CodeSuggestions::Tasks::CodeCompletion)
        end
      end
    end

    context 'without skip_generate_comment_prefix prefix' do
      let(:generate_prefix) { 'GitLab Duo Generate: ' }
      let(:case_insensitive_prefixes) do
        [
          'GitLab duo generate: ',
          'gitLab Duo Generate: ',
          'gitLab Duo generate: ',
          'gitLab duo generate: '
        ]
      end

      subject { described_class.task(skip_generate_comment_prefix: false, params: params) }

      it_behaves_like 'correct task detector'
    end

    context 'with skip_generate_comment_prefix prefix' do
      let(:generate_prefix) { '' }
      let(:case_insensitive_prefixes) { Array.new(4, '') }

      subject { described_class.task(skip_generate_comment_prefix: true, params: params) }

      it_behaves_like 'correct task detector'
    end
  end
end
