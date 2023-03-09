# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search, feature_category: :global_search do
  describe '.hash_namespace_id' do
    it 'returns modulo of string hash value' do
      namespace_id = instance_double(Integer)
      hash_value = 123
      maximum = 100

      expect(namespace_id).to receive_message_chain(:to_s, :hash).and_return hash_value
      expect(described_class.hash_namespace_id(namespace_id, maximum: maximum)).to eq(hash_value % maximum)
    end

    context 'when namespace id is nil' do
      it 'returns nil' do
        expect(described_class.hash_namespace_id(nil)).to be_nil
      end
    end
  end
end
