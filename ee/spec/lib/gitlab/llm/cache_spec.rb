# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Cache, :clean_gitlab_redis_cache, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let(:uuid) { 'uuid' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:payload) do
    {
      timestamp: timestamp,
      request_id: uuid,
      errors: ['some error1', 'another error'],
      response_body: 'response'
    }
  end

  subject { described_class.new(user) }

  before do
    other_user = create(:user)
    other_cache = described_class.new(other_user)

    other_cache.add(payload.merge(response_body: 'other user unrelated cache'))
  end

  describe '#add' do
    it 'adds new message' do
      expect(subject.all).to be_empty

      subject.add(payload)

      expected_data = payload
        .except(:errors)
        .merge(error: 'some error1. another error')
        .with_indifferent_access
      expect(subject.all).to eq([expected_data.with_indifferent_access])
    end

    context 'when ai_redis_cache is disabled' do
      before do
        stub_feature_flags(ai_redis_cache: false)
      end

      it 'does not add new message' do
        expect(subject.all).to be_empty

        subject.add(payload)

        expect(subject.all).to be_empty
      end
    end

    context 'with MAX_MESSAGES limit' do
      before do
        stub_const('Gitlab::Llm::Cache::MAX_MESSAGES', 2)
      end

      it 'removes oldes messages if we reach maximum message limit' do
        subject.add(payload.merge(response_body: 'msg1'))
        subject.add(payload.merge(response_body: 'msg2'))

        expect(subject.all).to match([
          a_hash_including('response_body' => 'msg1'),
          a_hash_including('response_body' => 'msg2')
        ])

        subject.add(payload.merge(response_body: 'msg3'))

        expect(subject.all).to match([
          a_hash_including('response_body' => 'msg2'),
          a_hash_including('response_body' => 'msg3')
        ])
      end
    end
  end

  describe '#get' do
    context 'when there is both request and response' do
      before do
        subject.add(payload.merge(response_body: nil))
        subject.add(payload.merge(response_body: 'msg'))
      end

      it 'gets response by request id' do
        data = subject.get(uuid)

        expect(data).not_to be_nil
        expect(data['response_body']).to eq('msg')
      end
    end

    context 'when there is only request' do
      before do
        subject.add(payload.merge(response_body: nil))
      end

      it 'returns nil' do
        data = subject.get(uuid)

        expect(data).to be_nil
      end
    end

    context 'when there is no record with this request id' do
      it 'returns nil' do
        data = subject.get(uuid)

        expect(data).to be_nil
      end
    end
  end

  describe '#all' do
    it 'returns all records for this user' do
      subject.add(payload.merge(response_body: 'msg1'))
      subject.add(payload.merge(response_body: 'msg2'))

      expect(subject.all).to match([
        a_hash_including('response_body' => 'msg1'),
        a_hash_including('response_body' => 'msg2')
      ])
    end
  end
end
