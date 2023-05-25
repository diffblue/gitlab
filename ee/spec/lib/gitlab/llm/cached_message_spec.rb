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
end
