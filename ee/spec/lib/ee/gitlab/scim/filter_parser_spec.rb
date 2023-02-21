# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe EE::Gitlab::Scim::FilterParser, feature_category: :system_access do
  describe '#operator' do
    it 'is extracted from the filter' do
      expect(described_class.new('displayName ne ""').operator).to eq 'ne'
    end
  end

  describe '#valid?' do
    it 'succeeds when the operator is supported' do
      expect(described_class.new('userName eq "nick"')).to be_valid
    end

    it 'fails with unsupported operators' do
      expect(described_class.new('userName is "nick"')).not_to be_valid
    end

    it 'fails when the attribute path is unsupported' do
      expect(described_class.new('user_name eq "nick"')).not_to be_valid
    end
  end

  describe '#params' do
    it 'returns a mapping to filter on' do
      expect(described_class.new('userName eq "nick"').params).to eq(username: 'nick')
    end

    it 'returns an empty hash when invalid' do
      expect(described_class.new('userName is "nick"').params).to eq({})
    end
  end
end
