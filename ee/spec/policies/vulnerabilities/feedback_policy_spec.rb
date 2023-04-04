# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FeedbackPolicy, feature_category: :vulnerability_management do
  include ExternalAuthorizationServiceHelpers

  let(:current_user) { create(:user) }
  let(:project) { create(:project, :public, namespace: current_user.namespace) }

  subject { described_class.new(current_user, vulnerability_feedback) }

  describe 'create_vulnerability_feedback' do
    context 'when issue cannot be created' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :issue) }

      context 'when issues feature is disabled' do
        before do
          project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
        end

        it 'does not allow to create issue feedback' do
          is_expected.to be_disallowed(:create_vulnerability_feedback)
        end
      end

      context 'when user does not have permission to create issue in project' do
        subject { described_class.new(nil, vulnerability_feedback) }

        it 'does not allow to create issue feedback' do
          is_expected.to be_disallowed(:create_issue)
          is_expected.to be_disallowed(:create_vulnerability_feedback)
        end
      end
    end

    context 'when merge request cannot be created' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :merge_request) }

      context 'when merge request feature is disabled' do
        before do
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
        end

        it 'does not allow to create merge request feedback' do
          is_expected.to be_disallowed(:create_vulnerability_feedback)
        end
      end

      context 'when user does not have permission to create merge_request in project' do
        subject { described_class.new(nil, vulnerability_feedback) }

        it 'does not allow to create merge request feedback' do
          is_expected.to be_disallowed(:create_merge_request_in)
          is_expected.to be_disallowed(:create_vulnerability_feedback)
        end
      end

      context 'when user does not have developer permission' do
        # guest can create merge request IN
        let(:guest) { create(:user) }

        subject { described_class.new(guest, vulnerability_feedback) }

        before do
          project.add_guest(guest)
        end

        it 'does not allow to create merge request feedback' do
          is_expected.to be_allowed(:create_merge_request_in)
          is_expected.to be_disallowed(:create_vulnerability_feedback)
        end
      end

      context 'with security bot' do
        let(:current_user) { create(:user, :security_bot) }
        let_it_be_with_reload(:project) { create(:project, :public) }

        before do
          stub_licensed_features(vulnerability_auto_fix: true)
        end

        context 'when auto-fix is enabled' do
          it { is_expected.to be_allowed(:create_vulnerability_feedback) }
        end

        context 'when auto-fix is disabled' do
          before do
            project.security_setting.update!(
              auto_fix_dependency_scanning: false,
              auto_fix_container_scanning: false
            )
          end

          it { is_expected.to be_disallowed(:create_vulnerability_feedback) }
        end
      end
    end
  end

  describe 'update_vulnerability_feedback' do
    context 'when feedback type is issue' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :issue) }

      it 'does not allow to update issue feedback' do
        is_expected.to be_disallowed(:update_vulnerability_feedback)
      end
    end

    context 'when feedback type is merge_request' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :merge_request) }

      it 'does not allow to update merge request feedback' do
        is_expected.to be_disallowed(:update_vulnerability_feedback)
      end
    end

    context 'when feedback type is dismissal' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :dismissal) }

      it 'allows to update dismissal feedback' do
        is_expected.to be_allowed(:update_vulnerability_feedback)
      end
    end
  end

  describe 'destroy_vulnerability_feedback' do
    context 'when feedback type is issue' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :issue) }

      it 'does not allow to destroy issue feedback' do
        is_expected.to be_disallowed(:destroy_vulnerability_feedback)
      end
    end

    context 'when feedback type is merge_request' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :merge_request) }

      it 'does not allow to destroy merge request feedback' do
        is_expected.to be_disallowed(:destroy_vulnerability_feedback)
      end
    end

    context 'when feedback type is dismissal' do
      let(:vulnerability_feedback) { Vulnerabilities::Feedback.new(project: project, feedback_type: :dismissal) }

      it 'allows to destroy dismissal feedback' do
        is_expected.to be_allowed(:destroy_vulnerability_feedback)
      end
    end
  end
end
