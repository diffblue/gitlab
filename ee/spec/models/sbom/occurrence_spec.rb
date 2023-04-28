# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Occurrence, type: :model, feature_category: :dependency_management do
  let_it_be(:occurrence) { build(:sbom_occurrence) }

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
    subject { build(:sbom_occurrence) }

    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_uniqueness_of(:uuid).case_insensitive }
  end

  describe '.order_by_id' do
    let_it_be(:first) { create(:sbom_occurrence) }
    let_it_be(:second) { create(:sbom_occurrence) }

    it 'returns records sorted by id' do
      expect(described_class.order_by_id).to eq([first, second])
    end
  end

  describe '.order_by_component_name' do
    let_it_be(:occurrence_1) { create(:sbom_occurrence, component: create(:sbom_component, name: 'component_1')) }
    let_it_be(:occurrence_2) { create(:sbom_occurrence, component: create(:sbom_component, name: 'component_2')) }

    it 'returns records sorted by component name asc' do
      expect(described_class.order_by_component_name('asc').map(&:name)).to eq(%w[component_1 component_2])
    end

    it 'returns records sorted by component name desc' do
      expect(described_class.order_by_component_name('desc').map(&:name)).to eq(%w[component_2 component_1])
    end
  end

  describe '.order_by_package_name' do
    let_it_be(:occurrence_nuget) { create(:sbom_occurrence, packager_name: 'nuget') }
    let_it_be(:occurrence_npm) { create(:sbom_occurrence, packager_name: 'npm') }
    let_it_be(:occurrence_null) { create(:sbom_occurrence, source: nil) }

    it 'returns records sorted by package name asc' do
      expect(described_class.order_by_package_name('asc').map(&:packager)).to eq(%w[npm nuget])
    end

    it 'returns records sorted by package name desc' do
      expect(described_class.order_by_package_name('desc').map(&:packager)).to eq(%w[nuget npm])
    end
  end

  describe '#name' do
    let(:component) { build(:sbom_component, name: 'rails') }
    let(:occurrence) { build(:sbom_occurrence, component: component) }

    it 'delegates name to component' do
      expect(occurrence.name).to eq('rails')
    end
  end

  describe '#version' do
    let(:component_version) { build(:sbom_component_version, version: '6.1.6.1') }
    let(:occurrence) { build(:sbom_occurrence, component_version: component_version) }

    it 'delegates version to component_version' do
      expect(occurrence.version).to eq('6.1.6.1')
    end

    context 'when component_version is nil' do
      let(:occurrence) { build(:sbom_occurrence, component_version: nil) }

      it 'returns nil' do
        expect(occurrence.version).to be_nil
      end
    end
  end

  describe 'source delegation' do
    let(:source_attributes) do
      {
        'category' => 'development',
        'input_file' => { 'path' => 'package-lock.json' },
        'source_file' => { 'path' => 'package.json' },
        'package_manager' => { 'name' => 'npm' },
        'language' => { 'name' => 'JavaScript' }
      }
    end

    let(:source) { build(:sbom_source, source: source_attributes) }
    let(:occurrence) { build(:sbom_occurrence, source: source) }

    describe '#packager' do
      subject(:packager) { occurrence.packager }

      it 'delegates packager to source' do
        expect(packager).to eq('npm')
      end

      context 'when source is nil' do
        let(:occurrence) { build(:sbom_occurrence, source: nil) }

        it { is_expected.to be_nil }
      end
    end

    describe '#location' do
      subject(:location) { occurrence.location }

      it 'returns expected location data' do
        expect(location).to eq(
          {
            blob_path: "/#{occurrence.project.full_path}/-/blob/#{occurrence.commit_sha}/#{source.input_file_path}",
            path: source.input_file_path,
            top_level: false,
            ancestors: nil
          }
        )
      end

      context 'when source is nil' do
        let(:occurrence) { build(:sbom_occurrence, source: nil) }

        it 'returns nil values' do
          expect(location).to eq(
            {
              blob_path: nil,
              path: nil,
              top_level: false,
              ancestors: nil
            }
          )
        end
      end
    end
  end
end
