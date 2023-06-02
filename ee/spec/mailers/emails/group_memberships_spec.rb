# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::GroupMemberships do
  include EmailSpec::Matchers

  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:group_member, :owner, group: group) }

  let(:csv) { CSV.parse_line("a,b,c\nd,e,f") }

  describe "#memberships_export_email" do
    subject { Notify.memberships_export_email(csv_data: csv, requested_by: owner.user, group: group) }

    it { is_expected.to have_subject('Exported group membership list') }
    it { is_expected.to be_delivered_to([owner.user.notification_email_for(group)]) }

    it 'contains one attachment', :freeze_time do
      expect(subject.attachments.size).to eq(1)
      expect(subject.attachments[0].content_type).to eq('text/csv')
      expect(subject.attachments[0].filename).to eq("#{group.full_path.parameterize}_group_memberships_#{Date.current.iso8601}.csv")
    end

    it 'properly renders email' do
      email_content = "Hi, Attached to this email is the list of members of #{group.name} in CSV format."

      expect(subject.html_part.body).to have_content(email_content)
      expect(subject.text_part.body).to have_content(email_content)
    end
  end
end
