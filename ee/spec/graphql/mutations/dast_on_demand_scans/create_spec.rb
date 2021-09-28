# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastOnDemandScans::Create do
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, group: group) }
  let(:full_path) { project.full_path }
  let(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let(:dast_site_profile_id) { dast_site_profile.to_global_id }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        dast_site_profile_id: dast_site_profile_id
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

        it 'returns a pipeline_url containing the correct path' do
          actual_url = subject[:pipeline_url]
          pipeline = Ci::Pipeline.last
          expected_url = Rails.application.routes.url_helpers.project_pipeline_url(
            project,
            pipeline
          )
          expect(actual_url).to eq(expected_url)
        end

        context 'when the dast_site_profile does not exist' do
          it 'raises an exception' do
            dast_site_profile.destroy!

            expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'when dast_scanner_profile_id is provided' do
          let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, target_timeout: 200, spider_timeout: 5000, use_ajax_spider: true, show_debug_messages: true, scan_type: 'passive') }
          let(:dast_scanner_profile_id) { dast_scanner_profile.to_global_id }

          subject do
            mutation.resolve(
              full_path: full_path,
              dast_site_profile_id: dast_site_profile_id,
              dast_scanner_profile_id: dast_scanner_profile_id
            )
          end

          it 'has no errors' do
            group.add_owner(user)

            expect(subject[:errors]).to be_empty
          end

          it 'passes additional arguments to the underlying service object' do
            args = hash_including(
              dast_profile: nil,
              branch: project.default_branch,
              ci_configuration: kind_of(String)
            )

            expect_any_instance_of(::AppSec::Dast::Scans::RunService).to receive(:execute).with(args).and_call_original

            subject
          end

          context 'when scan_type=active' do
            let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, scan_type: 'active') }

            context 'when target is not validated' do
              it 'communicates failure' do
                expect(subject[:errors]).to include('Cannot run active scan against unvalidated target')
              end
            end

            context 'when target is validated' do
              it 'has no errors' do
                create(:dast_site_validation, state: :passed, dast_site_token: create(:dast_site_token, project: project, url: dast_site_profile.dast_site.url))

                expect(subject[:errors]).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
