# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AssetType'] do
  let_it_be(:project) { create(:project) }
  let(:fields) do
    %i[name type url]
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_api_fuzzing_report, project: project) }

  before do
    stub_licensed_features(api_fuzzing: true, security_dashboard: true)

    project.add_developer(user)
  end

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  specify { expect(described_class.graphql_name).to eq('AssetType') }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'checking field contents' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              securityReportFindings {
                nodes {
                  title
                  assets {
                    name
                    type
                    url
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'checks the contents of the assets field' do
      vulnerabilities = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')
      vulnerability = vulnerabilities.find { |v| v['title'] == "CORS misconfiguration at 'http://127.0.0.1:7777/api/users'" }

      asset = vulnerability['assets'].first

      expect(asset).to eq({
                            "name" => "Test Postman Collection",
                            "type" => "postman",
                            "url" => "http://localhost/test.collection"
                          })
    end
  end
end
