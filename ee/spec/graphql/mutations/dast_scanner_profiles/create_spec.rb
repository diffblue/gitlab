# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastScannerProfiles::Create, :dynamic_analysis,
                                                       feature_category: :dynamic_application_security_testing do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:profile_name) { SecureRandom.hex }
  let(:dast_scanner_profile) { DastScannerProfile.find_by(project: project, name: profile_name) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        profile_name: profile_name,
        scan_type: DastScannerProfile.scan_types[:passive],
        use_ajax_spider: false,
        show_debug_messages: false
      )
    end

    context 'when the project does not exist' do
      let(:full_path) { SecureRandom.hex }

      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can run a dast scan' do
      before do
        group.add_owner(user)
      end

      it 'returns the dast_scanner_profile id' do
        expect(subject[:id]).to eq(dast_scanner_profile.to_global_id)
      end

      it 'returns the complete dast_scanner_profile' do
        expect(subject[:dast_scanner_profile]).to eq(dast_scanner_profile)
      end

      it 'calls the dast_scanner_profile creation service' do
        service = double(described_class)
        result = double('result', success?: false, errors: [])

        expected_args = {
          project: project,
          current_user: user,
          params: {
            name: profile_name,
            scan_type: DastScannerProfile.scan_types[:passive],
            show_debug_messages: false,
            use_ajax_spider: false
          }
        }

        expect(::AppSec::Dast::ScannerProfiles::CreateService).to receive(:new).with(expected_args).and_return(service)

        expect(service).to receive(:execute).and_return(result)

        subject
      end

      context 'when the dast_scanner_profile already exists' do
        it 'returns an error' do
          subject

          response = mutation.resolve(
            full_path: full_path,
            profile_name: profile_name,
            scan_type: DastScannerProfile.scan_types[:passive],
            use_ajax_spider: false,
            show_debug_messages: false
          )

          expect(response[:errors]).to include('Name has already been taken')
        end
      end
    end
  end
end
