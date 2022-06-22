# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::DismissService do
  include AccessMatchersGeneric

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let!(:pipeline) { create(:ee_ci_pipeline, :with_dast_report, :success, project: project) }
  let(:vulnerability) { create(:vulnerability, :with_findings, project: project) }
  let(:dismiss_findings) { true }
  let(:service) { described_class.new(user, vulnerability, dismiss_findings: dismiss_findings) }

  subject(:dismiss_vulnerability) { service.execute }

  context 'when deprecate_vulnerabilities_feedback is enabled' do
    before do
      stub_feature_flags(deprecate_vulnerabilities_feedback: true)
    end

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'calls vulnerability statistics utility services in order'

      context 'when the `dismiss_findings` argument is false' do
        let(:dismiss_findings) { false }

        it 'dismisses only vulnerability' do
          freeze_time do
            dismiss_vulnerability

            expect(vulnerability.reload).to(
              have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
            expect(vulnerability.findings).to include not_have_vulnerability_dismissal_feedback
          end
        end
      end

      context 'when the `dismiss_findings` argument is not false' do
        it 'dismisses a vulnerability and its associated findings with correct attributes' do
          freeze_time do
            dismiss_vulnerability

            expect(vulnerability.reload).to(
              have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
            expect(vulnerability.findings).to all not_have_vulnerability_dismissal_feedback
            expect(vulnerability.finding.dismissal_feedback).to eq nil
          end
        end
      end

      context 'when comment is added' do
        let(:comment) { 'Dismissal Comment' }
        let(:service) { described_class.new(user, vulnerability, comment) }

        it 'dismisses a vulnerability and its associated findings with comment', :aggregate_failures do
          freeze_time do
            dismiss_vulnerability

            aggregate_failures do
              expect(vulnerability.reload).to(
                have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
              expect(vulnerability.findings).to all not_have_vulnerability_dismissal_feedback
              expect(vulnerability.findings.map(&:dismissal_feedback)).to all eq nil
            end
          end
        end
      end

      context 'when the dismissal_reason is added' do
        let(:dismissal_reason) { 'used_in_tests' }
        let(:service) { described_class.new(user, vulnerability, nil, dismissal_reason) }

        it 'dismisses a vulnerability and its associated findings with comment', :aggregate_failures do
          dismiss_vulnerability

          expect(vulnerability.reload).to have_attributes(state: 'dismissed', dismissed_by: user)
          expect(vulnerability.findings).to all not_have_vulnerability_dismissal_feedback
          expect(vulnerability.findings.map(&:dismissal_feedback)).to all eq nil
        end
      end

      it 'creates note' do
        expect(SystemNoteService).to receive(:change_vulnerability_state).with(vulnerability, user)

        dismiss_vulnerability
      end

      context 'when there is a finding dismissal error' do
        before do
          allow(service).to receive(:dismiss_vulnerability_findings).and_return(
            described_class::FindingsDismissResult.new(false, broken_finding, 'something went wrong'))
        end

        let(:broken_finding) { vulnerability.findings.first }

        it 'responds with error' do
          expect(dismiss_vulnerability.errors.messages).to eq(
            base: ["failed to dismiss associated finding(id=#{broken_finding.id}): something went wrong"])
        end
      end

      context 'when security dashboard feature is disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'raises an "access denied" error' do
          expect { dismiss_vulnerability }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end

  context 'when deprecate_vulnerabilities_feedback is disabled' do
    before do
      stub_feature_flags(deprecate_vulnerabilities_feedback: false)
    end

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'calls vulnerability statistics utility services in order'

      context 'when the `dismiss_findings` argument is false' do
        let(:dismiss_findings) { false }

        it 'dismisses only vulnerability' do
          freeze_time do
            dismiss_vulnerability

            expect(vulnerability.reload).to(
              have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
            expect(vulnerability.findings).not_to include have_vulnerability_dismissal_feedback
          end
        end
      end

      context 'when the `dismiss_findings` argument is not false' do
        it 'dismisses a vulnerability and its associated findings with correct attributes' do
          freeze_time do
            dismiss_vulnerability

            expect(vulnerability.reload).to(
              have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
            expect(vulnerability.findings).to all have_vulnerability_dismissal_feedback
            expect(vulnerability.finding.dismissal_feedback.finding_uuid).to eq(vulnerability.finding.uuid_v5)
          end
        end
      end

      context 'when comment is added' do
        let(:comment) { 'Dismissal Comment' }
        let(:service) { described_class.new(user, vulnerability, comment) }

        it 'dismisses a vulnerability and its associated findings with comment', :aggregate_failures do
          freeze_time do
            dismiss_vulnerability

            aggregate_failures do
              expect(vulnerability.reload).to(
                have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
              expect(vulnerability.findings).to all have_vulnerability_dismissal_feedback
              expect(vulnerability.findings.map(&:dismissal_feedback)).to(
                all(have_attributes(comment: comment, comment_author: user, comment_timestamp: be_like_time(Time.current), pipeline_id: pipeline.id)))
            end
          end
        end
      end

      context 'when the dismissal_reason is added' do
        let(:dismissal_reason) { 'used_in_tests' }
        let(:service) { described_class.new(user, vulnerability, nil, dismissal_reason) }

        it 'dismisses a vulnerability and its associated findings with comment', :aggregate_failures do
          dismiss_vulnerability

          expect(vulnerability.reload).to have_attributes(state: 'dismissed', dismissed_by: user)
          expect(vulnerability.findings).to all have_vulnerability_dismissal_feedback
          expect(vulnerability.findings.map(&:dismissal_feedback)).to all(have_attributes(dismissal_reason: dismissal_reason))
        end
      end

      it 'creates note' do
        expect(SystemNoteService).to receive(:change_vulnerability_state).with(vulnerability, user)

        dismiss_vulnerability
      end

      context 'when there is a finding dismissal error' do
        before do
          allow(service).to receive(:dismiss_vulnerability_findings).and_return(
            described_class::FindingsDismissResult.new(false, broken_finding, 'something went wrong'))
        end

        let(:broken_finding) { vulnerability.findings.first }

        it 'responds with error' do
          expect(dismiss_vulnerability.errors.messages).to eq(
            base: ["failed to dismiss associated finding(id=#{broken_finding.id}): something went wrong"])
        end
      end

      context 'when security dashboard feature is disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'raises an "access denied" error' do
          expect { dismiss_vulnerability }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end

  describe 'permissions' do
    context 'when admin mode is enabled', :enable_admin_mode do
      it { expect { dismiss_vulnerability }.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { expect { dismiss_vulnerability }.to be_denied_for(:admin) }
    end
    it { expect { dismiss_vulnerability }.to be_allowed_for(:owner).of(project) }
    it { expect { dismiss_vulnerability }.to be_allowed_for(:maintainer).of(project) }
    it { expect { dismiss_vulnerability }.to be_allowed_for(:developer).of(project) }

    it { expect { dismiss_vulnerability }.to be_denied_for(:auditor) }
    it { expect { dismiss_vulnerability }.to be_denied_for(:reporter).of(project) }
    it { expect { dismiss_vulnerability }.to be_denied_for(:guest).of(project) }
    it { expect { dismiss_vulnerability }.to be_denied_for(:anonymous) }
  end
end
