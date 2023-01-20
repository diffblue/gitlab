# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastScannerProfiles::Update, :dynamic_analysis,
                                                       feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, target_timeout: 200, spider_timeout: 5000) }

  let_it_be(:new_profile_name) { SecureRandom.hex }
  let_it_be(:new_target_timeout) { dast_scanner_profile.target_timeout + 1 }
  let_it_be(:new_spider_timeout) { dast_scanner_profile.spider_timeout + 1 }
  let_it_be(:new_scan_type) { (DastScannerProfile.scan_types.keys - [DastScannerProfile.last.scan_type]).first }
  let_it_be(:new_use_ajax_spider) { !dast_scanner_profile.use_ajax_spider }
  let_it_be(:new_show_debug_messages) { !dast_scanner_profile.show_debug_messages }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        id: scanner_profile_id,
        profile_name: new_profile_name,
        target_timeout: new_target_timeout,
        spider_timeout: new_spider_timeout,
        scan_type: new_scan_type,
        use_ajax_spider: new_use_ajax_spider,
        show_debug_messages: new_show_debug_messages
      )
    end

    let(:scanner_profile_id) { dast_scanner_profile.to_global_id }

    context 'when on demand scan feature is enabled' do
      context 'when the user can run a DAST scan' do
        before do
          project.add_developer(user)
        end

        context 'when the user omits unrequired elements' do
          subject do
            mutation.resolve(
              id: scanner_profile_id,
              profile_name: new_profile_name,
              target_timeout: new_target_timeout,
              spider_timeout: new_spider_timeout
            )
          end

          it 'does not update those elements' do
            updated_dast_scanner_profile = subject[:id].find

            aggregate_failures do
              expect(updated_dast_scanner_profile.scan_type).to eq(dast_scanner_profile.scan_type)
              expect(updated_dast_scanner_profile.use_ajax_spider).to eq(dast_scanner_profile.use_ajax_spider)
              expect(updated_dast_scanner_profile.show_debug_messages).to eq(dast_scanner_profile.show_debug_messages)
            end
          end
        end

        it 'updates the dast_scanner_profile' do
          dast_scanner_profile = subject[:id].find

          aggregate_failures do
            expect(dast_scanner_profile.name).to eq(new_profile_name)
            expect(dast_scanner_profile.target_timeout).to eq(new_target_timeout)
            expect(dast_scanner_profile.spider_timeout).to eq(new_spider_timeout)
            expect(dast_scanner_profile.scan_type).to eq(new_scan_type)
            expect(dast_scanner_profile.use_ajax_spider).to eq(new_use_ajax_spider)
            expect(dast_scanner_profile.show_debug_messages).to eq(new_show_debug_messages)
          end
        end

        it 'returns the complete dast_scanner_profile' do
          expect(subject[:dast_scanner_profile]).to eq(dast_scanner_profile)
        end

        context 'when dast scanner profile does not exist' do
          let(:scanner_profile_id) { global_id_of(model_name: 'DastScannerProfile', id: 'does_not_exist') }

          it 'raises an exception' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end
    end
  end
end
