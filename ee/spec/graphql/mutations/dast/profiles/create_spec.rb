# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Dast::Profiles::Create, :dynamic_analysis,
                                                  feature_category: :dynamic_application_security_testing do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:branch_name) { project.default_branch }
  let(:description) { SecureRandom.hex }
  let(:name) { SecureRandom.hex }
  let(:run_after_create) { false }
  let(:dast_profile) { Dast::Profile.find_by(project: project, name: name) }
  let(:dast_profile_schedule) { nil }
  let(:tag_list) { %w[ruby postgres] }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: developer }, field: nil) }

  before do
    ActsAsTaggableOn::Tag.create!(name: 'ruby')
    ActsAsTaggableOn::Tag.create!(name: 'postgres')
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: project.full_path,
        name: name,
        description: description,
        branch_name: branch_name,
        dast_site_profile_id: dast_site_profile.to_global_id,
        dast_scanner_profile_id: dast_scanner_profile.to_global_id,
        run_after_create: run_after_create,
        dast_profile_schedule: dast_profile_schedule,
        tag_list: tag_list
      )
    end

    context 'when the feature is licensed' do
      context 'when the user can run a dast scan' do
        let(:dast_profile_schedule) { attributes_for(:dast_profile_schedule) }

        it 'returns the dast_profile' do
          expect(subject[:dast_profile]).to eq(dast_profile)
        end

        it 'returns the dast_profile_schedule' do
          expect(subject[:dast_profile_schedule]).to eq(dast_profile.dast_profile_schedule)
        end

        context 'when run_after_create=true' do
          let(:run_after_create) { true }

          it_behaves_like 'it checks branch permissions before creating a DAST on-demand scan pipeline'
          it_behaves_like 'it creates a DAST on-demand scan pipeline'

          it_behaves_like 'it delegates scan creation to another service' do
            let(:delegated_params) { hash_including(dast_profile: instance_of(Dast::Profile)) }
          end
        end
      end
    end
  end
end
