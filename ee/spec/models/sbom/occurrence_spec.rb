# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Occurrence, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:component).required }
    it { is_expected.to belong_to(:component_version) }
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:source) }
  end

  describe 'loose foreign key on sbom_occurrences.pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:sbom_occurrence, pipeline: parent) }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:commit_sha) }

    describe '#component_version_belongs_to_component' do
      let_it_be(:component) { create(:sbom_component) }
      let_it_be(:component_version) { create(:sbom_component_version, component: component) }

      subject(:occurrence) { build(:sbom_occurrence, component: component, component_version: component_version) }

      context 'when component_version belongs to the same component' do
        it { is_expected.to be_valid }
      end

      context 'when component_version is null' do
        let_it_be(:component_version) { nil }

        it { is_expected.to be_valid }
      end

      context 'when component_version belongs to a different component' do
        let_it_be(:other_component) { create(:sbom_component) }
        let_it_be(:component_version) { create(:sbom_component_version, component: other_component) }

        it 'does not validate' do
          expect(occurrence).not_to be_valid
          expect(occurrence.errors[:component_version]).to include('must belong to the associated component')
        end
      end
    end
  end
end
