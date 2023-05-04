# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::ComplianceFrameworkReportsController, feature_category: :compliance_management do
  let_it_be(:user) { create :user, name: 'UserName' }
  let_it_be(:group) { create :group, name: 'GroupName' }

  before do
    login_as user
  end

  describe 'GET /groups/*group_id/-/security/compliance_framework_reports(.:format)' do
    subject(:request_export) { get group_security_compliance_framework_reports_path group, format: :csv }

    context 'when user does not have access to dashboard' do
      it 'renders not found' do
        request_export

        expect(response).to have_gitlab_http_status :not_found
      end
    end

    context 'when user has access to compliance reports' do
      let(:email_notice_message) { 'An email will be sent with the report attached after it is generated.' }

      before do
        stub_licensed_features group_level_compliance_dashboard: true
        group.add_owner user
      end

      it "defers email generation and redirects with message on following page" do
        expect(ComplianceManagement::FrameworkExportMailerWorker).to(
          receive(:perform_async).with(user.id, group.id)
        )

        request_export

        expect(response).to have_gitlab_http_status :redirect

        follow_redirect!

        expect(response.body).to include(email_notice_message)
      end
    end
  end
end
