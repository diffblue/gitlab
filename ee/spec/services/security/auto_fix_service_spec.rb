# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::AutoFixService, feature_category: :vulnerability_management do
  describe '#execute' do
    subject(:execute_service) { described_class.new(project, pipeline).execute }

    let(:pipeline) { create(:ee_ci_pipeline, :success, project: project) }
    let(:project) { create(:project, :custom_repo, files: { 'yarn.lock' => yarn_lock_content }) }
    let(:remediations_folder) { Rails.root.join('ee/spec/fixtures/security_reports/remediations') }

    let(:yarn_lock_content) do
      File.read(
        File.join(remediations_folder, "yarn.lock")
      )
    end

    let(:remediation_diff) do
      Base64.encode64(
        File.read(
          File.join(remediations_folder, "remediation.patch")
        )
      )
    end

    shared_examples 'disabled auto-fix error' do
      it 'returns error' do
        result = execute_service

        expect(result).to be_error
        expect(result.message).to eq('Auto fix is disabled')
      end
    end

    before do
      stub_licensed_features(vulnerability_auto_fix: true)
    end

    context 'when remediations' do
      let!(:vulnerability_finding) do
        create(:vulnerabilities_finding_with_remediation, :yarn_remediation, :identifier,
               project: project,
               report_type: :dependency_scanning,
               summary: 'Test remediation',
               vulnerability: vulnerability)
      end

      let(:vulnerability) { create(:vulnerability) }

      before do
        create(:vulnerabilities_finding_pipeline, finding: vulnerability_finding, pipeline: pipeline)

        # Added the foloowing two stubbing just to pass the specs as this service is currently not in use
        # we can update this and also refactor the service for feedback deprecation when we will work on this service
        allow_next_instance_of(Vulnerabilities::FindOrCreateFromSecurityFindingService) do |instance|
          allow(instance).to receive(:execute)
            .and_return(ServiceResponse.success(payload: { vulnerability: vulnerability }))
        end

        allow_next_instance_of(VulnerabilityMergeRequestLinks::CreateService) do |instance|
          allow(instance).to receive(:execute)
            .and_return(ServiceResponse.success(payload: { payload: {} }))
        end
      end

      it 'creates MR' do
        result = execute_service

        identifier = vulnerability.identifiers.last
        merge_request = MergeRequest.last!

        expect(result).to be_success
        expect(merge_request.title).to eq("Resolve vulnerability: Cipher with no integrity")
        expect(merge_request.description).to include("[#{identifier.external_id}](#{identifier.url})")
      end

      it 'assign auto-fix label' do
        execute_service

        label = MergeRequest.last.labels.last
        title = ::Security::AutoFixLabelService::LABEL_PROPERTIES[:title]

        expect(label.title).to eq(title)
      end

      context 'when merge request exists' do
        let(:feedback) { create(:vulnerability_feedback, :merge_request) }

        before do
          allow_next_found_instance_of(Vulnerabilities::Finding) do |finding|
            allow(finding).to receive(:merge_request_feedback).and_return(feedback)
          end
        end

        it 'does not create second merge request' do
          execute_service

          expect(Vulnerabilities::Feedback.count).to eq(1)
        end
      end
    end

    context 'with disabled auto-fix' do
      before do
        project.security_setting.update!(auto_fix_dependency_scanning: false, auto_fix_container_scanning: false)
      end

      it_behaves_like 'disabled auto-fix error'
    end

    context 'with disabled licensed feature' do
      before do
        stub_licensed_features(vulnerability_auto_fix: false)
      end

      it_behaves_like 'disabled auto-fix error'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(security_auto_fix: false)
      end

      it_behaves_like 'disabled auto-fix error'
    end

    context 'without remediations' do
      before do
        create(:vulnerabilities_finding, :with_pipeline, report_type: :dependency_scanning, project: project)
      end

      it 'does not create merge request' do
        result = execute_service

        expect(result).to be_error
        expect(result.message).to eq('Impossible to create Merge Requests')
      end
    end
  end
end
