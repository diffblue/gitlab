# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Cache, :clean_gitlab_redis_chat, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let(:request_id) { 'uuid' }
  let(:timestamp) { Time.current.to_s }
  let(:payload) do
    {
      timestamp: timestamp,
      request_id: request_id,
      errors: ['some error1', 'another error'],
      role: 'user',
      content: 'response'
    }
  end

  subject { described_class.new(user) }

  before do
    other_user = create(:user)
    other_cache = described_class.new(other_user)

    other_cache.add(payload.merge(content: 'other user unrelated cache'))
  end

  describe '#add' do
    it 'adds new message', :aggregate_failures do
      uuid = 'unique_id'

      expect(SecureRandom).to receive(:uuid).once.and_return(uuid)
      expect(subject.find_all).to be_empty

      subject.add(payload)

      last = subject.find_all.last
      expect(last.id).to eq(uuid)
      expect(last.request_id).to eq(request_id)
      expect(last.errors).to eq(['some error1. another error'])
      expect(last.content).to eq('response')
      expect(last.role).to eq('user')
      expect(last.timestamp).not_to be_nil
    end

    it 'does not set error when errors are empty' do
      payload[:errors] = []

      subject.add(payload)

      last = subject.find_all.last
      expect(last.errors).to eq([])
    end

    it 'raises an exception when role is missing' do
      payload[:role] = nil

      expect { subject.add(payload) }.to raise_error(ArgumentError, "Invalid role ''")
    end

    it 'raises an exception when role is invalid' do
      payload[:role] = 'bot'

      expect { subject.add(payload) }.to raise_error(ArgumentError, "Invalid role 'bot'")
    end

    context 'when ai_redis_cache is disabled' do
      before do
        stub_feature_flags(ai_redis_cache: false)
      end

      it 'does not add new message' do
        expect(subject.find_all).to be_empty

        subject.add(payload)

        expect(subject.find_all).to be_empty
      end
    end

    context 'with MAX_MESSAGES limit' do
      before do
        stub_const('Gitlab::Llm::Cache::MAX_MESSAGES', 2)
      end

      it 'removes oldes messages if we reach maximum message limit' do
        subject.add(payload.merge(content: 'msg1'))
        subject.add(payload.merge(content: 'msg2'))

        expect(subject.find_all.map(&:content)).to eq(%w[msg1 msg2])

        subject.add(payload.merge(content: 'msg3'))

        expect(subject.find_all.map(&:content)).to eq(%w[msg2 msg3])
      end
    end
  end

  describe '#find_all' do
    let(:filters) { {} }

    before do
      subject.add(payload.merge(content: 'msg1', role: 'user', request_id: '1'))
      subject.add(payload.merge(content: 'msg2', role: 'assistant', request_id: '2'))
      subject.add(payload.merge(content: 'msg3', role: 'assistant', request_id: '3'))
    end

    it 'returns all records for this user' do
      expect(subject.find_all(filters).map(&:content)).to eq(%w[msg1 msg2 msg3])
    end

    context 'when filtering by role' do
      let(:filters) { { roles: ['user'] } }

      it 'returns only records for this role' do
        expect(subject.find_all(filters).map(&:content)).to eq(%w[msg1])
      end
    end

    context 'when filtering by request_ids' do
      let(:filters) { { request_ids: %w[2 3] } }

      it 'returns only records with the same request_id' do
        expect(subject.find_all(filters).map(&:content)).to eq(%w[msg2 msg3])
      end
    end
  end
end
