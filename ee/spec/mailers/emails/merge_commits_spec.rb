# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::MergeCommits, feature_category: :compliance_management do
  include EmailSpec::Matchers

  include_context 'gitlab email notification'

  let_it_be(:current_user, reload: true) { create(:user, email: "current@email.com", name: 'www.example.com') }
  let_it_be(:group) { create(:group, name: 'Kombucha lovers') }
  let_it_be(:project) { create(:project, :repository, namespace: group, name: 'Starter kit') }

  before_all do
    project.add_maintainer(current_user)
  end

  describe '#merge_requests_csv_email' do
    let(:frozen_time) { Time.current }
    let(:filename) { "#{group.id}-merge-commits-#{frozen_time.to_i}.csv" }
    let(:group_url) { Gitlab::Routing.url_helpers.group_url(group) }
    let(:expected_text) do
      "Your Chain of Custody CSV export for the group %{group_name} has been added to this email as an attachment."
    end

    let(:csv_data) do
      Groups::ComplianceReportCsvService.new(
        current_user,
        group
      ).csv_data.payload
    end

    let(:expected_plain_text) { format(expected_text, group_name: group.name) }
    let(:expected_html_text) do
      group_name_with_link = %r{<a .*?href="#{group_url}".*?>#{group.name}</a>}
      Regexp.new(format(expected_text, group_name: group_name_with_link))
    end

    subject do
      travel_to frozen_time do
        Notify.merge_commits_csv_email(current_user, group, csv_data, filename)
      end
    end

    it { expect(subject.subject).to eq("#{group.name} | Exported Chain of Custody Report") }
    it { expect(subject.to).to contain_exactly(current_user.notification_email_for(project.group)) }
    it { expect(subject.text_part.to_s).to match(expected_plain_text) }
    it { expect(subject.html_part.to_s).to match(expected_html_text) }
  end
end
