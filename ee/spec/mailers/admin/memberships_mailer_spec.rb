# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::MembershipsMailer do
  include EmailSpec::Matchers

  describe '.instance_memberships_export' do
    let(:user) { create(:admin) }

    subject { described_class.instance_memberships_export(requested_by: user) }

    it 'contains memberships csv as an attachment' do
      freeze_time do
        expect(subject.attachments.size).to eq(1)
        expect(subject.attachments[0].content_type).to eq('text/csv')
        expect(subject.attachments[0].filename).to eq("gitlab_memberships_#{Date.current.iso8601}.csv")
      end
    end

    it { is_expected.to have_subject 'GitLab Memberships CSV Export' }
    it { is_expected.to deliver_to user.notification_email_or_default }
    it { is_expected.to have_body_text('The CSV export you requested of all user memberships is attached to this email.') }
  end
end
