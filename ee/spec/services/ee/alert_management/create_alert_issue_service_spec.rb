# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::CreateAlertIssueService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let_it_be(:alert) { create(:alert_management_alert, project: project) }

  let(:created_issue) { Issue.last! }

  describe '#execute' do
    subject(:execute) { described_class.new(alert, user).execute }

    before do
      project.add_developer(user)
      stub_licensed_features(incident_metric_upload: true)
    end

    it 'copies any metric images' do
      image = create(:alert_metric_image, alert: alert)

      execute

      incident = Issue.incident.last

      expect(incident.metric_images.count).to eq(1)

      metric_image = incident.metric_images.first
      expect(metric_image.url).to eq(image.url)
      expect(metric_image.url_text).to eq(image.url_text)
      expect(metric_image.filename).to eq(image.filename)
      expect(metric_image.file).not_to eq(image.file)
    end
  end
end
