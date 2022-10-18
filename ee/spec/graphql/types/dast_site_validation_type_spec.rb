# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastSiteValidation'] do
  let_it_be(:dast_site_validation) { create(:dast_site_validation, state: :passed) }
  let_it_be(:project) { dast_site_validation.dast_site_token.project }
  let_it_be(:user) { create(:user) }
  let_it_be(:fields) { %i[id status normalizedTargetUrl validationStartedAt] }

  let(:response) do
    GitlabSchema.execute(
      query,
      context: {
        current_user: user
      },
      variables: {
        fullPath: project.full_path,
        normalized_target_urls: [dast_site_validation.url_base],
        status: Types::DastSiteValidationStatusEnum.values.fetch('PASSED_VALIDATION').value
      }
    ).as_json
  end

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastSiteValidation') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'dast_site_validations' do
    before do
      project.add_developer(user)
    end

    let(:query) do
      %(
        query project($fullPath: ID!, $normalizedTargetUrls: [String!]) {
          project(fullPath: $fullPath) {
            dastSiteValidations(normalizedTargetUrls: $normalizedTargetUrls) {
              edges { node { id status normalizedTargetUrl } }
            }
          }
        }
      )
    end

    describe 'status field' do
      subject { response.dig('data', 'project', 'dastSiteValidations', 'edges', 0, 'node', 'status') }

      it { is_expected.to eq('PASSED_VALIDATION') }
    end

    describe 'validation_started_at field' do
      subject { response.dig('data', 'project', 'dastSiteValidations', 'edges', 0, 'node', 'validation_started_at') }

      it { is_expected.to eq(dast_site_validation.validation_started_at) }
    end
  end
end
