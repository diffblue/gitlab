# frozen_string_literal: true

RSpec.shared_examples 'validates presence of any field' do
  describe '.any_field_present' do
    let_it_be(:evidence) { build(:vulnerabilties_finding_evidence) }
    let_it_be(:test_object) { described_class.new(evidence: evidence) }

    it 'is invalid if there are no fields present' do
      expect(test_object).not_to be_valid
    end

    described_class::DATA_FIELDS.each do |field|
      it "validates on a single field present when #{field} is set" do
        test_object[field] = "test-object-#{field}"
        expect(test_object).to be_valid
      end
    end
  end
end
