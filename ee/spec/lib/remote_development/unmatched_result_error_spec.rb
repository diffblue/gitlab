# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe RemoteDevelopment::UnmatchedResultError, feature_category: :remote_development do
  let(:unmatched_message_class) { stub_const('UnmatchedMessage', Class.new(RemoteDevelopment::Message)) }
  let(:unmatched_message) { unmatched_message_class.new }

  context "for an 'ok' Result" do
    it 'has a correct message' do
      expected_msg = "Failed to pattern match 'ok' Result containing message of type: UnmatchedMessage"

      expect do
        raise described_class.new(result: Result.ok(unmatched_message))
      end.to raise_error(described_class, expected_msg)
    end
  end

  context "for an 'err' Result" do
    it 'has a correct message' do
      expected_msg = "Failed to pattern match 'err' Result containing message of type: UnmatchedMessage"

      expect do
        raise described_class.new(result: Result.err(unmatched_message))
      end.to raise_error(described_class, expected_msg)
    end
  end
end
