# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DastSiteProfileResolver do
  include GraphqlHelpers

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_site_profile1) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_site_profile2) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_site_profile3) do
    dast_site = create(:dast_site, project: project, url: 'https://site1.com/, https://site2.com/')

    create(:dast_site_profile, project: project, dast_site: dast_site)
  end

  let(:current_user) { developer }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::DastSiteProfileType.connection_type)
  end

  context 'when resolving a single DAST site profile' do
    subject { sync(single_dast_site_profile(id: dast_site_profile1.to_global_id)) }

    it { is_expected.to eq dast_site_profile1 }
  end

  context 'when resolving multiple DAST site profiles' do
    subject { sync(dast_site_profiles) }

    it { is_expected.to contain_exactly(dast_site_profile1, dast_site_profile2, dast_site_profile3) }

    context 'when the feature is disabled' do
      before do
        stub_licensed_features(security_on_demand_scans: false)
      end

      it { is_expected.to be_empty }
    end

    context 'when the user does not have access' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_empty }
    end
  end

  private

  def dast_site_profiles
    resolve(described_class, obj: project, ctx: { current_user: current_user })
  end

  def single_dast_site_profile(**args)
    resolve(described_class.single, obj: project, args: args, ctx: { current_user: current_user })
  end
end
