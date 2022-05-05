# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Dast::Profiles::Delete do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }

  let(:dast_profile_gid) { dast_profile.to_global_id }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject { mutation.resolve(id: dast_profile_gid) }

    context 'when the user cannot read the project' do
      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can destroy a DAST profile' do
      before do
        project.add_developer(user)
      end

      it 'deletes the profile' do
        expect { subject }.to change { Dast::Profile.count }.by(-1)
      end

      context 'when the dast_profile does not exist' do
        let(:dast_profile_gid) { global_id_of(id: 'does_not_exist', model_name: 'Dast::Profile') }

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when DAST profile belongs to a project the user does not have access to' do
        let_it_be(:dast_profile) { create(:dast_profile) }

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when deletion fails' do
        it 'returns an error' do
          allow_next_instance_of(::AppSec::Dast::Profiles::DestroyService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message: 'Profile failed to delete')
            )
          end

          expect(subject[:errors]).to include('Profile failed to delete')
        end
      end
    end
  end
end
