# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastProfile'], :dynamic_analysis,
                                                  feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:object) { create(:dast_profile, project: project) }
  let_it_be(:dast_pre_scan_verification) { create(:dast_pre_scan_verification, dast_profile: object) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:tag_list) { %w[ruby postgres] }

  let_it_be(:fields) do
    %i[id name description dastSiteProfile dastScannerProfile dastProfileSchedule branch editPath
      dastPreScanVerification tagList]
  end

  specify { expect(described_class.graphql_name).to eq('DastProfile') }
  specify { expect(described_class).to require_graphql_authorizations(:read_on_demand_dast_scan) }

  before do
    ActsAsTaggableOn::Tag.create!(name: 'ruby')
    ActsAsTaggableOn::Tag.create!(name: 'postgres')
    stub_licensed_features(security_on_demand_scans: true)
  end

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to have_graphql_field(:branch, calls_gitaly?: true) }

  describe 'branch field' do
    it 'correctly resolves the field' do
      expected_result = Dast::Branch.new(object)

      expect(resolve_field(:branch, object, current_user: user)).to eq(expected_result)
    end
  end

  describe 'editPath field' do
    it 'correctly resolves the field' do
      expected_result = Gitlab::Routing.url_helpers.edit_project_on_demand_scan_path(project, object)

      expect(resolve_field(:edit_path, object, current_user: user)).to eq(expected_result)
    end
  end

  describe 'dastProfileSchedule field' do
    it 'correctly resolves the field' do
      expect(resolve_field(:dast_profile_schedule, object, current_user: user)).to eq(object.dast_profile_schedule)
    end
  end

  describe 'dast_pre_scan_verification field' do
    it 'correctly resolves the field' do
      expect(resolve_field(:dast_pre_scan_verification,
                           object, current_user: user)).to eq(object.dast_pre_scan_verification)
    end

    context 'when the feature flag is not enabled' do
      before do
        stub_feature_flags(dast_pre_scan_verification: false)
      end

      it 'is nil' do
        expect(resolve_field(:dast_pre_scan_verification, object, current_user: user)).to be_nil
      end
    end
  end

  describe 'tagList field' do
    it 'correctly resolves the field' do
      expect(resolve_field(:tag_list, object, current_user: user)).to eq(object.tag_list)
    end
  end
end
