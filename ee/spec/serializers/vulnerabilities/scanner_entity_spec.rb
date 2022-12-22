# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ScannerEntity, feature_category: :vulnerability_management do
  let(:scanner) { create(:vulnerabilities_scanner) }

  let(:entity) do
    described_class.represent(scanner)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:name, :external_id, :vendor)
    end
  end
end
