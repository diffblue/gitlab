# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::DependenciesFinder, feature_category: :dependency_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:occurrence_1) { create(:sbom_occurrence, packager_name: 'nuget', project: project) }
  let_it_be(:occurrence_2) { create(:sbom_occurrence, packager_name: 'npm', project: project) }
  let_it_be(:occurrence_3) { create(:sbom_occurrence, source: nil, project: project) }

  subject(:dependencies) { described_class.new(project, params: params).execute }

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

        expect(packagers).to eq(%w[npm nuget])
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

        expect(packagers).to eq(%w[nuget npm])
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
