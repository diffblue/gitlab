# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/keys_first_and_values_first'

RSpec.describe RuboCop::Cop::Gitlab::KeysFirstAndValuesFirst do
  let(:msg) { described_class::MSG }

  subject(:cop) { described_class.new }

  describe 'keys.first' do
    it 'flags and autocorrects' do
      expect_offense(<<~RUBY)
        hash.keys.first
                  ^^^^^ Prefer `.each_key.first` over `.keys.first`. [...]
      RUBY

      expect_correction(<<~RUBY)
        hash.each_key.first
      RUBY
    end

    it 'does not flag unrelated code' do
      expect_no_offenses(<<~RUBY)
        array.first
        hash.keys.last
        hash.keys
        keys.first
      RUBY
    end
  end

  describe 'values.first' do
    it 'flags and autocorrects' do
      expect_offense(<<~RUBY)
        hash.values.first
                    ^^^^^ Prefer `.each_value.first` over `.values.first`. [...]
      RUBY

      expect_correction(<<~RUBY)
        hash.each_value.first
      RUBY
    end

    it 'does not flag unrelated code' do
      expect_no_offenses(<<~RUBY)
        array.first
        hash.values.last
        hash.values
        values.first
      RUBY
    end
  end
end
