# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastSiteProfiles::Delete do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let!(:dast_site_profile) { create(:dast_site_profile, project: project) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(id: dast_site_profile.to_global_id)
    end

    context 'when on demand scan feature is enabled' do
      context 'when the user can run a dast scan' do
        before do
          project.add_developer(user)
        end

        it 'deletes the dast_site_profile' do
          expect { subject }.to change { DastSiteProfile.count }.by(-1)
        end

        context 'when there is an issue deleting the dast_site_profile' do
          it 'returns an error' do
            allow_next_instance_of(::AppSec::Dast::SiteProfiles::DestroyService) do |service|
              allow(service).to receive(:execute).and_return(double(success?: false, errors: ['Name is weird']))
            end

            expect(subject[:errors]).to include('Name is weird')
          end
        end
      end
    end
  end
end
