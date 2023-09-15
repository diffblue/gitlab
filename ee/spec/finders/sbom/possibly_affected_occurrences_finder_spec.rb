# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::PossiblyAffectedOccurrencesFinder, feature_category: :software_composition_analysis do
  let_it_be(:project) { create(:project) }
  let_it_be(:matching_component) { create(:sbom_component, name: 'abab', purl_type: 'npm') }
  let_it_be(:non_matching_component) { create(:sbom_component, name: 'abab', purl_type: 'golang') }
  let_it_be(:matching_component_version) do
    create(:sbom_component_version, component: matching_component, version: '1.0.4')
  end

  let_it_be(:non_matching_component_versions) do
    [
      create(:sbom_component_version, component: non_matching_component),
      create(:sbom_component_version)
    ]
  end

  let!(:matching_occurrences) do
    create_list(:sbom_occurrence, 3, component: matching_component,
      component_version: matching_component_version, project: project)
  end

  let_it_be(:non_matching_occurrences) do
    non_matching_component_versions.map do |version|
      create(:sbom_occurrence, component: version.component, component_version: version)
    end
  end

  let_it_be(:package_name) { matching_component.name }
  let_it_be(:purl_type) { matching_component.purl_type }

  # use a method instead of a subject to avoid rspec memoization
  def possibly_affected_occurrences
    occurrences = []
    described_class.new(purl_type: purl_type, package_name: package_name).execute_in_batches do |batch|
      batch.each do |possibly_affected_occurrence|
        occurrences << possibly_affected_occurrence
      end
    end
    occurrences
  end

  context 'when no component matches the provided details' do
    context 'as the package_name does not match' do
      let_it_be(:package_name) { 'non-matching-package-name' }

      it 'returns nil' do
        expect(described_class.new(purl_type: purl_type, package_name: package_name).execute_in_batches).to be_nil
      end

      it { expect(possibly_affected_occurrences).to be_empty }
    end

    context 'as the purl_type does not match' do
      let_it_be(:purl_type) { 'non-matching-purl-type' }

      it 'returns nil' do
        expect(described_class.new(purl_type: purl_type, package_name: package_name).execute_in_batches).to be_nil
      end

      it { expect(possibly_affected_occurrences).to be_empty }
    end
  end

  context 'when a component matches the provided details' do
    context 'and the project for the component does not have cvs enabled' do
      it { expect(possibly_affected_occurrences).to be_empty }
    end

    context 'and the project for the component has cvs enabled' do
      let_it_be(:project) { create(:project, :with_cvs) }

      it 'returns the possibly affected occurrences' do
        expect(possibly_affected_occurrences).to match_array(matching_occurrences)
      end

      it 'does not execute an N+1 query' do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { possibly_affected_occurrences.first }

        create(:sbom_component_version, component: matching_component, version: '1.0.5')
        create(:sbom_component_version, component: matching_component, version: '1.0.6')
        create(:sbom_component_version, component: matching_component, version: '1.0.7')

        expect { possibly_affected_occurrences.first }.not_to exceed_all_query_limit(control)
      end

      context 'and an sbom occurrence exists without a version' do
        let_it_be(:sbom_occurrence_without_component_version) do
          create(:sbom_occurrence, component: matching_component, component_version: nil)
        end

        it 'does not return the sbom occurrence without a component version' do
          expect(possibly_affected_occurrences).not_to include(sbom_occurrence_without_component_version)
        end
      end

      it 'pre-loads associations to avoid an N+1 query' do
        described_class.new(purl_type: purl_type, package_name: package_name).execute_in_batches do |batch|
          batch.each do |record|
            queries = ActiveRecord::QueryRecorder.new do
              record.component
              record.component_version
              record.source
              record.pipeline
              record.project
            end
            expect(queries.count).to be_zero
          end
        end
      end
    end
  end
end
