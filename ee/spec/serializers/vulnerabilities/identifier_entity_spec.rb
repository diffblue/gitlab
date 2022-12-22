# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::IdentifierEntity, feature_category: :vulnerability_management do
  let(:identifier) { create(:vulnerabilities_identifier) }

  let(:entity) do
    described_class.represent(identifier)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:external_type, :external_id, :name, :url)
    end
  end
end
