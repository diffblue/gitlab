# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Dast::Profiles::Run, :dynamic_analysis,
                                               feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be_with_refind(:project) { create(:project, :repository) }

  let_it_be(:user) { create(:user) }
  let_it_be(:branch_name) { project.default_branch }
  let_it_be(:dast_profile) { create(:dast_profile, project: project, branch_name: branch_name) }

  let(:dast_profile_id) { dast_profile.to_global_id }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(id: dast_profile_id)
    end

    context 'when on demand scan licensed feature is not available' do
      it 'raises an exception' do
        stub_licensed_features(security_on_demand_scans: false)
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when the user can run a dast scan' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'it creates a DAST on-demand scan pipeline' do
          context 'when there is a dast_site_profile_secret_variable associated with the dast_profile' do
            let_it_be(:dast_site_profile_secret_variable) { create(:dast_site_profile_secret_variable, dast_site_profile: dast_profile.dast_site_profile, raw_value: 'hello, world') }

            it 'makes the variable available to the dast build' do
              subject

              dast_build = pipeline.builds.find_by!(name: 'dast')
              variable = dast_build.variables.find { |var| var[:key] == dast_site_profile_secret_variable.key }

              expect(Base64.strict_decode64(variable.value)).to include('hello, world')
            end
          end
        end

        it_behaves_like 'it checks branch permissions before creating a DAST on-demand scan pipeline' do
          let(:dast_profile) { create(:dast_profile, project: project, branch_name: branch_name) }
        end

        it_behaves_like 'it delegates scan creation to another service' do
          let(:delegated_params) { hash_including(dast_profile: dast_profile) }
        end

        context 'when the dast_profile does not exist' do
          let(:dast_profile_id) { global_id_of(model_name: 'Dast::Profile', id: 'does_not_exist') }

          it 'raises an exception' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when scan_type=active' do
          let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, scan_type: 'active') }
          let(:dast_profile) { create(:dast_profile, project: project, dast_scanner_profile: dast_scanner_profile) }

          context 'when target is not validated' do
            it 'communicates failure' do
              expect(subject[:errors]).to include('Cannot run active scan against unvalidated target')
            end
          end

          context 'when target is validated' do
            it 'has no errors' do
              create(:dast_site_validation, state: :passed, dast_site_token: create(:dast_site_token, project: project, url: dast_profile.dast_site_profile.dast_site.url))

              expect(subject[:errors]).to be_empty
            end
          end
        end
      end
    end
  end
end
