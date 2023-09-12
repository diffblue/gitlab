# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Query.project(fullPath).securityTrainingUrls", :sidekiq_inline, feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let_it_be(:security_training_provider) { create(:security_training_provider, name: "Kontra") }
  let_it_be(:security_training) do
    create(:security_training, project: project, provider: security_training_provider)
  end

  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: "cwe", external_id: 80, name: "cwe-80") }
  let(:identifier_external_ids) { ["[cwe]-[80]-[cwe-80]"] }
  let(:filename) { "foo/bar/baz.rb" }
  let(:provider_response) do
    {
      "name" => "Stored Cross Site Scripting",
      "cwe" => [80],
      "language" => "java",
      "link" => "https://application.security/gitlab/free-application-security-training/owasp-top-10-stored-cross-site-scripting"
    }
  end

  let(:query) do
    <<~GQL
      query {
        project(fullPath: "#{project.full_path}") {
          securityTrainingUrls (
            identifierExternalIds: #{identifier_external_ids},
            filename: "#{filename}"
          ) {
            name
            status
            url
          }
        }
      }
    GQL
  end

  before do
    stub_licensed_features(security_dashboard: true)
  end

  context "when unauthenticated" do
    let_it_be(:current_user) { nil }

    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like "a working graphql query that returns no data"
  end

  context "when authenticated" do
    let_it_be(:current_user) { create(:user) }

    context "when not authorized" do
      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like "a working graphql query that returns no data"
    end

    context "when authorized" do
      before_all do
        project.add_developer(current_user)
      end

      before do
        stub_request(:get, "https://example.com/?cwe=80&language=ruby")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Authorization" => "Bearer #{Security::TrainingProviders::KontraUrlService::BEARER_TOKEN}",
              "User-Agent" => "Ruby"
            }
          ).to_return(
            status: 200,
            body: Gitlab::Json.dump(provider_response),
            headers: { "Content-Type" => "application/json" }
          )

        post_graphql(query, current_user: current_user)
      end

      it "returns the security training urls" do
        security_training_urls = graphql_data.dig("project", "securityTrainingUrls")
        expect(security_training_urls.size).to eq 1
        expect(security_training_urls.first).to include(
          { "name" => "Kontra", "status" => "PENDING" }
        )
      end
    end
  end
end
