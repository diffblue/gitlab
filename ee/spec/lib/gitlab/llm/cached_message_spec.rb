# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::CachedMessage, feature_category: :shared do
  let(:timestamp) { Time.current }
  let(:data) do
    {
      'timestamp' => timestamp.to_s,
      'id' => 'uuid',
      'request_id' => 'original_request_id',
      'error' => 'some error1. another error',
      'role' => 'user',
      'content' => 'response'
    }
  end

  subject { described_class.new(data) }

  describe '#to_global_id' do
    it 'returns global ID' do
      expect(subject.to_global_id.to_s).to eq('gid://gitlab/Gitlab::Llm::CachedMessage/uuid')
    end
  end

  describe '#errors' do
    it 'returns message error wrapped as an array' do
      expect(subject.errors).to eq([data['error']])
    end
  end

  describe '#conversation_reset?' do
    it 'returns true for reset message' do
      data['content'] = '/reset'

      expect(subject.conversation_reset?).to be_truthy
    end

    it 'returns false for regular message' do
      expect(subject.conversation_reset?).to be_falsey
    end
  end

  describe '#size' do
    it 'returns 0 if content is missing' do
      data['content'] = nil

      expect(subject.size).to eq(0)
    end

    it 'returns size of the content if present' do
      expect(subject.size).to eq(data['content'].size)
    end
  end
end
