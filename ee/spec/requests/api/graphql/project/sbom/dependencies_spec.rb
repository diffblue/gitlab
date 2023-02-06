# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dependencies', feature_category: :dependency_management do
  include ApiHelpers
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:variables) { { fullPath: project.full_path } }
  let_it_be(:fields) do
    <<~FIELDS
      name
      version
      packager
      location {
        blobPath
        path
      }
    FIELDS
  end

  let_it_be(:query) do
    %(
      query($fullPath: ID!) {
        project(fullPath: $fullPath) {
          dependencies {
            nodes {
              #{fields}
            }
          }
        }
      }
    )
  end

  let!(:occurrences) { create_list(:sbom_occurrence, 5, project: project) }

  before do
    stub_licensed_features(dependency_scanning: true)
  end

  subject { post_graphql(query, current_user: user, variables: variables) }

  it 'returns the expected dependency data when performing a well-formed query with an authorized user' do
    subject

    actual = graphql_data_at(:project, :dependencies, :nodes)
    expected = occurrences.map do |occurrence|
      {
        'name' => occurrence.name,
        'version' => occurrence.version,
        'packager' => occurrence.packager,
        'location' => {
          'blobPath' => "/#{project.full_path}/-/blob/#{occurrence.commit_sha}/#{occurrence.source.input_file_path}",
          'path' => occurrence.source.input_file_path
        }
      }
    end

    expect(actual).to match_array(expected)
  end

  it 'does not make N+1 queries' do
    control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: user, variables: variables) }

    create(:sbom_occurrence, project: project)

    expect { post_graphql(query, current_user: user, variables: variables) }.not_to exceed_query_limit(control)
  end

  context 'when dependencies have no source data' do
    let!(:occurrences) { create_list(:sbom_occurrence, 5, project: project, source: nil) }

    it 'returns nil for data which originates from a source' do
      subject

      actual = graphql_data_at(:project, :dependencies, :nodes)
      expected = occurrences.map do |occurrence|
        {
          'name' => occurrence.name,
          'version' => occurrence.version,
          'packager' => nil,
          'location' => {
            'blobPath' => nil,
            'path' => nil
          }
        }
      end

      expect(actual).to match_array(expected)
    end
  end

  context 'when dependencies have no version data' do
    let!(:occurrences) { create_list(:sbom_occurrence, 5, project: project, component_version: nil) }

    it 'returns a nil version' do
      subject

      actual = graphql_data_at(:project, :dependencies, :nodes)
      expected = occurrences.map do |occurrence|
        {
          'name' => occurrence.name,
          'version' => nil,
          'packager' => occurrence.packager,
          'location' => {
            'blobPath' => "/#{project.full_path}/-/blob/#{occurrence.commit_sha}/#{occurrence.source.input_file_path}",
            'path' => occurrence.source.input_file_path
          }
        }
      end

      expect(actual).to match_array(expected)
    end
  end

  context 'with an unauthorized user' do
    let_it_be(:user) { create(:user).tap { |user| project.add_guest(user) } }

    it 'does not return dependency data' do
      subject
      expect(graphql_data_at(:project, :dependencies)).to be_blank
    end
  end
end
