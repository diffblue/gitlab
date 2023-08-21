# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::ModelSelector, feature_category: :code_suggestions do
  using RSpec::Parameterized::TableSyntax

  let(:selector) { described_class.new(prefix: prefix) }

  describe '#task_type' do
    subject { selector.task_type }

    context 'with the prefix, suffix produces the correct type' do
      where(:prefix, :type) do
        # Standard code generation comments
        "# GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"  | :code_generation
        '// GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers' | :code_generation
        "#GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"   | :code_generation
        '//GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers'  | :code_generation

        # Line breaks at the end of the comment
        "# GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n"  | :code_generation
        "// GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n" | :code_generation
        "#GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n"   | :code_generation
        "//GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers\n"  | :code_generation

        # These have characters _before_ the comment
        "end\n\n# GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"    | :code_generation
        "}\n\n\n\n// GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers" | :code_generation
        "    #GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers"        | :code_generation
        "   \r\n   //GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers" | :code_generation

        # These rely on case-insensitivity
        "# GitLab duo generate: A function that outputs the first 20 fibonacci numbers"  | :code_generation
        '// gitLab Duo Generate: A function that outputs the first 20 fibonacci numbers' | :code_generation
        "#gitLab Duo generate: A function that outputs the first 20 fibonacci numbers"   | :code_generation
        '//gitLab duo generate: A function that outputs the first 20 fibonacci numbers'  | :code_generation

        # These are too short to be considered generation
        "# GitLab Duo Generate: A func" | :code_completion
        '// GitLab Duo Generate: A fun' | :code_completion
        "#GitLab Duo Generate: A func"  | :code_completion
        '//GitLab Duo Generate: A fu'   | :code_completion

        # These include no comments at all
        'def fibonacci(i)'        | :code_completion
        'function fibonacci(x) {' | :code_completion
      end

      with_them do
        it { is_expected.to eq type }
      end
    end

    it 'only takes the last example in to account when the last comment is a code generation' do
      code_block = <<~TEXT
        # GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers
        def fibonacci(x)

        # GitLab Duo Generate: A function that rounds every number to the nearest 10

      TEXT

      expect(described_class.new(prefix: code_block).task_type).to eq(:code_generation)
    end

    it 'only takes the last example in to account when the last comment is a code suggestion' do
      code_block = <<~TEXT
        # GitLab Duo Generate: A function that outputs the first 20 fibonacci numbers

        def fibonacci(x)

      TEXT

      expect(described_class.new(prefix: code_block).task_type).to eq(:code_completion)
    end
  end
end
