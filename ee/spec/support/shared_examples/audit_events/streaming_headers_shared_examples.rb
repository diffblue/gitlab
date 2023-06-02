# frozen_string_literal: true

RSpec.shared_examples 'audit event streaming header' do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_length_of(:key).is_at_most(255) }
    it { is_expected.to validate_length_of(:value).is_at_most(255) }
  end

  describe '#to_hash' do
    it 'returns the correct hash' do
      expect(subject.to_hash).to eq({ 'foo' => 'bar' })
    end
  end
end
