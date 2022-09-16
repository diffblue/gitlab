# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::FeatureFlagWrapper do
  let_it_be(:email) { build_stubbed(:user).email }

  subject(:wrapper) { described_class.new(email) }

  describe '#flipper_id' do
    it 'returns a string containing the email' do
      expect(subject.flipper_id).to eq("Email:#{email}")
    end
  end
end
