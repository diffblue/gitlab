# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastSiteValidations::Revoke do
  let_it_be(:dast_site_validation1) { create(:dast_site_validation, state: :passed) }
  let_it_be(:dast_site_validation2) { create(:dast_site_validation) }
  let_it_be(:project) { dast_site_validation1.project }
  let_it_be(:user) { create(:user) }

  let(:full_path) { project.full_path }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        normalized_target_url: dast_site_validation1.url_base
      )
    end

    context 'when on demand scan feature is enabled' do
      context 'when the project does not exist' do
        let(:full_path) { SecureRandom.hex }

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the user can run a dast scan' do
        before do
          project.add_developer(user)
        end

        it 'deletes dast_site_validations where state=passed' do
          aggregate_failures do
            expect { subject }.to change { DastSiteValidation.count }.from(2).to(1)

            expect { dast_site_validation1.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        it 'correctly calls AppSec::Dast::SiteValidations::RevokeService' do
          params = { container: project, params: { url_base: dast_site_validation1.url_base } }

          expect(AppSec::Dast::SiteValidations::RevokeService).to receive(:new).with(params).and_call_original

          subject
        end
      end
    end
  end
end
