# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::ComplianceFrameworks, feature_category: :compliance_management do
  include EmailSpec::Matchers

  include_context 'gitlab email notification'

  describe '#compliance_frameworks_csv_email', travel_to: '2022-02-24' do
    let_it_be(:user_email) { 'sam@email.com' }
    let_it_be(:current_user) { build_stubbed :user, email: user_email, name: 'UserName' }
    let_it_be(:group) { build_stubbed :group, name: 'GroupName' }

    let(:filename) { "2022-02-24-33-frameworks.csv" }
    let(:content_type) { "text/csv" }
    let(:csv_data) { "Group,Framework,isDefault\n1,GDPR,false" }

    let(:expected_text) do
      'Your Compliance Frameworks CSV export for the group "%{group_name}" has been attached to this email.'
    end

    let(:expected_html) do
      'Your Compliance Frameworks CSV export for the group %{group_link} has been attached to this email.'
    end

    let(:expected_plain_text) { format(expected_text, group_name: group.name) }
    let(:expected_html_text) do
      group_url = Gitlab::Routing.url_helpers.group_url group
      group_name_with_link = %r{<a .*?href="#{group_url}".*?>#{group.name}</a>}
      Regexp.new(format(expected_html, group_link: group_name_with_link))
    end

    subject(:mail) do
      Notify.compliance_frameworks_csv_email(
        user: current_user,
        group: group,
        attachment: csv_data,
        filename: filename
      )
    end

    it "renders an email with attachment" do
      expect(mail.subject).to eq("#{group.name} | Compliance Frameworks Export")
      expect(mail.to).to contain_exactly(user_email)
      expect(mail.text_part.to_s).to match(expected_plain_text)
      expect(mail.html_part.to_s).to match(expected_html_text)
      expect(mail.attachments.size).to eq(1)

      attachment = mail.attachments.first

      expect(attachment.content_type).to eq(content_type)
      expect(attachment.filename).to eq(filename)
    end
  end
end
