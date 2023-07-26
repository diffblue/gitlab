# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::DependenciesFinder, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:component_1) { create(:sbom_component, name: 'component-1') }
  let_it_be(:component_2) { create(:sbom_component, name: 'component-2') }
  let_it_be(:component_3) { create(:sbom_component, name: 'component-3') }
  let_it_be(:component_version_1) { create(:sbom_component_version, component: component_1) }
  let_it_be(:component_version_2) { create(:sbom_component_version, component: component_2) }
  let_it_be(:component_version_3) { create(:sbom_component_version, component: component_3) }

  let_it_be(:occurrence_1) do
    create(:sbom_occurrence, component_version: component_version_1, packager_name: 'nuget', project: project)
  end

  let_it_be(:occurrence_2) do
    create(:sbom_occurrence, component_version: component_version_2, packager_name: 'npm', project: project)
  end

  let_it_be(:occurrence_3) do
    create(:sbom_occurrence, component_version: component_version_3, source: nil, project: project)
  end

  shared_examples 'filter and sorting' do
    context 'without params' do
      let_it_be(:params) { {} }

      it 'returns the dependencies associated with the project ordered by id' do
        expect(dependencies.first.id).to eq(occurrence_1.id)
        expect(dependencies.last.id).to eq(occurrence_3.id)
      end
    end

    context 'with params' do
      context 'when sorted asc by names' do
        let_it_be(:params) do
          {
            sort: 'asc',
            sort_by: 'name'
          }
        end

        it 'returns array of data properly sorted' do
          expect(dependencies.first.name).to eq('component-1')
          expect(dependencies.last.name).to eq('component-3')
        end
      end

      context 'when sorted desc by names' do
        let_it_be(:params) do
          {
            sort: 'desc',
            sort_by: 'name'
          }
        end

        it 'returns array of data properly sorted' do
          expect(dependencies.first.name).to eq('component-3')
          expect(dependencies.last.name).to eq('component-1')
        end
      end

      context 'when sorted asc by packager' do
        let_it_be(:params) do
          {
            sort: 'asc',
            sort_by: 'packager'
          }
        end

        it 'returns array of data properly sorted' do
          packagers = dependencies.map(&:packager)

          expect(packagers).to eq(['npm', 'nuget', nil])
        end
      end

      context 'when sorted desc by packager' do
        let_it_be(:params) do
          {
            sort: 'desc',
            sort_by: 'packager'
          }
        end

        it 'returns array of data properly sorted' do
          packagers = dependencies.map(&:packager)

          expect(packagers).to eq([nil, 'nuget', 'npm'])
        end
      end

      context 'when filtered by package name npm' do
        let_it_be(:params) do
          {
            package_managers: %w[npm]
          }
        end

        it 'returns only records with packagers related to npm' do
          packagers = dependencies.map(&:packager)

          expect(packagers).to eq(%w[npm])
        end
      end

      context 'when filtered by component name' do
        let_it_be(:params) do
          {
            component_names: [occurrence_1.name]
          }
        end

        it 'returns only records corresponding to the filter' do
          component_names = dependencies.map(&:name)

          expect(component_names).to eq([occurrence_1.name])
        end
      end

      context 'when params is invalid' do
        let_it_be(:params) do
          {
            sort: 'invalid',
            sort_by: 'invalid'
          }
        end

        it 'returns the dependencies associated with the project ordered by id' do
          expect(dependencies.first.id).to eq(occurrence_1.id)
          expect(dependencies.last.id).to eq(occurrence_3.id)
        end
      end
    end
  end

  context 'with project' do
    subject(:dependencies) { described_class.new(project, params: params).execute }

    include_examples 'filter and sorting'
  end

  context 'with group' do
    subject(:dependencies) { described_class.new(group, params: params).execute }

    include_examples 'filter and sorting'
  end

  context 'with subgroup' do
    subject(:dependencies) { described_class.new(subgroup, params: params).execute }

    include_examples 'filter and sorting'
  end
end
