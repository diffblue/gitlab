# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingDismissService do
  include AccessMatchersGeneric

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let!(:build) { create(:ee_ci_build, :sast, pipeline: pipeline) }
  let!(:finding) { create(:vulnerabilities_finding, project: project) }
  let(:service) { described_class.new(user, finding) }

  subject(:dismiss_finding) { service.execute }

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    context 'when comment is added' do
      let(:comment) { 'Dismissal Comment' }
      let(:service) { described_class.new(user, finding, comment) }

      it 'dismisses a finding with comment', :aggregate_failures do
        freeze_time do
          dismiss_finding

          aggregate_failures do
            expect(finding.reload).to(have_attributes(state: 'dismissed'))
            expect(finding.dismissal_feedback).to have_attributes(comment: comment, comment_author: user, comment_timestamp: be_like_time(Time.current), pipeline_id: pipeline.id)
          end
        end
      end
    end

    context 'when the dismissal_reason is added' do
      let(:dismissal_reason) { 'used_in_tests' }
      let(:service) { described_class.new(user, finding, nil, dismissal_reason) }

      it 'dismisses a finding', :aggregate_failures do
        dismiss_finding

        expect(finding.reload).to have_attributes(state: 'dismissed')
        expect(finding.dismissal_feedback).to have_attributes(dismissal_reason: dismissal_reason)
      end
    end

    context 'when Vulnerabilities::Feedback creation fails' do
      let(:create_service_double) { instance_double("VulnerabilityFeedback::CreateService", execute: service_failure_payload) }
      let(:service_failure_payload) do
        {
          status: :error,
          message: errors_double
        }
      end

      let(:errors_double) { instance_double("ActiveModel::Errors", full_messages: error_messages_array) }
      let(:error_messages_array) { instance_double("Array", join: "something went wrong") }

      before do
        allow(VulnerabilityFeedback::CreateService).to receive(:new).and_return(create_service_double)
      end

      it 'returns the error' do
        expect(create_service_double).to receive(:execute).once

        result = dismiss_finding

        expect(result).not_to be_success
        expect(result.http_status).to be(:unprocessable_entity)
        expect(result.message).to eq("failed to dismiss finding: something went wrong")
      end
    end

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an "access denied" error' do
        result = dismiss_finding

        expect(result).not_to be_success
        expect(result.http_status).to be(:forbidden)
        expect(result.message).to eq("Access denied")
      end
    end
  end
end
