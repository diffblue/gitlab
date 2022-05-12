# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Framework do
  context 'validation' do
    let_it_be(:framework) { create(:compliance_framework) }

    subject { framework }

    it { is_expected.to validate_uniqueness_of(:namespace_id).scoped_to(:name) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_length_of(:color).is_at_most(10) }
    it { is_expected.to validate_length_of(:pipeline_configuration_full_path).is_at_most(255) }
  end

  describe 'color' do
    context 'with whitespace' do
      subject { create(:compliance_framework, color: ' #ABC123 ')}

      it 'strips whitespace' do
        expect(subject.color).to eq('#ABC123')
      end
    end
  end
end
