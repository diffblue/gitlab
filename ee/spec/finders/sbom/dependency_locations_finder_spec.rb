# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::DependencyLocationsFinder, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:occurrence_npm) { create(:sbom_occurrence, project: project) }
  let_it_be(:source_npm) { occurrence_npm.source }
  let_it_be(:component) { occurrence_npm.component }
  let_it_be(:source_bundler) { create(:sbom_source, packager_name: 'bundler', input_file_path: 'Gemfile.lock') }
  let_it_be(:occurrence_bundler) do
    create(:sbom_occurrence, source: source_bundler, component: component, project: project)
  end

  let(:namespace) { group }
  let(:params) { { search: 'file', component_id: component.id } }

  subject(:dependencies) { described_class.new(namespace: namespace, params: params).execute }

  it 'returns records filtered by search' do
    expect(dependencies).to eq([occurrence_bundler])
  end

  context 'with multiple occurrences' do
    before do
      create(:sbom_occurrence, source: source_bundler, component: component, project: project)
      stub_const("#{described_class}::DEFAULT_PER_PAGE", 1)
    end

    it 'returns array based on the limit' do
      expect(dependencies.count).to be 1
    end
  end

  context 'with unrelated group' do
    let(:namespace) { create(:group) }

    it 'returns empty array' do
      expect(dependencies).to be_empty
    end
  end

  context 'with unrelated component' do
    let(:params) { { search: 'file', component_id: create(:sbom_component).id } }

    it 'returns empty array' do
      expect(dependencies).to be_empty
    end
  end

  context 'with missing parameters' do
    let(:params) { {} }

    it 'returns empty array' do
      expect(dependencies).to be_empty
    end
  end
end
