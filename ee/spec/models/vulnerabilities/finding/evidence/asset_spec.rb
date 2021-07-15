# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding::Evidence::Asset do
  it { is_expected.to belong_to(:evidence).class_name('Vulnerabilities::Finding::Evidence').inverse_of(:assets).required }

  it { is_expected.to validate_length_of(:type).is_at_most(2048) }
  it { is_expected.to validate_length_of(:name).is_at_most(2048) }
  it { is_expected.to validate_length_of(:url).is_at_most(2048) }

  describe '.any_field_present' do
    let_it_be(:evidence) { build(:vulnerabilties_finding_evidence) }
    let_it_be(:asset) { Vulnerabilities::Finding::Evidence::Asset.new(evidence: evidence) }

    it 'is invalid if there are no fields present' do
      expect(asset).not_to be_valid
    end

    it 'validates if there is only a type' do
      asset.type = 'asset-type'
      expect(asset).to be_valid
    end

    it 'validates if there is only a name' do
      asset.type = 'asset-name'
      expect(asset).to be_valid
    end

    it 'validates if there is only a url' do
      asset.type = 'asset-url.example'
      expect(asset).to be_valid
    end
  end
end
