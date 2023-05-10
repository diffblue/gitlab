# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'buildForecast', feature_category: :devops_reports do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:production) { create(:environment, :production, project: project) }
  let_it_be(:current_user) { create(:user).tap { |u| project.add_developer(u) } }

  let(:horizon) { 7 }
  let(:type) { 'deployment_frequency' }
  let(:context_gid) { project.to_gid }

  let(:mutation) do
    graphql_mutation('buildForecast', { type: type, context_id: context_gid, horizon: horizon },
      <<-QL.strip_heredoc
        forecast {
          status
          values {
            nodes {
              datapoint
              value
            }
          }
        }
    QL
    )
  end

  let(:mutation_response) { graphql_mutation_response('buildForecast') }

  around do |example|
    travel_to('2023-04-01') { example.run }
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  context 'when forecast is good enough' do
    before do
      # Create deployment frequency data

      (1.year.ago.to_date..Date.today).each do |date|
        create(:dora_daily_metrics,
          date: date,
          environment: production,
          deployment_frequency: (date.wday - 3).abs) # data has predictable patterns.
      end
    end

    let(:expected_forecast) do
      [3, 2, 1, 0, 1, 2, 3].map.with_index do |value, i|
        { 'datapoint' => (Date.today + 1 + i).strftime('%Y-%m-%d'), 'value' => value }
      end
    end

    it 'returns forecast values' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['forecast']['status']).to eq 'READY'
      expect(mutation_response['forecast']['values']['nodes']).to eq expected_forecast
    end
  end

  context 'when forecast is too weak' do
    before do
      # Create deployment frequency data

      (1.year.ago.to_date..Date.today).each.with_index do |date, i|
        create(:dora_daily_metrics,
          date: date,
          environment: production,
          deployment_frequency: i.odd? ? i : i**2
        )
      end
    end

    it 'returns no values' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['forecast']['status']).to eq 'UNAVAILABLE'
      expect(mutation_response['forecast']['values']['nodes']).to eq []
    end
  end

  context 'when forecast has invalid input' do
    let(:context_gid) { current_user.to_gid }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => 'Invalid context type. Project is expected.'))
    end
  end

  context 'when forecast context does not exist' do
    let(:context_gid) { Project.new(id: 999999).to_gid }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors)
        .to include(
          a_hash_including('message' => Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR))
    end
  end
end
