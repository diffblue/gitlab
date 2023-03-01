# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::CreateAlertIssueService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be_with_reload(:alert) { create(:alert_management_alert, project: project) }

  describe '#execute' do
    subject(:execute) { described_class.new(alert, user).execute }

    before do
      project.add_developer(user)
      stub_licensed_features(incident_metric_upload: true)
    end

    it 'copies any metric images' do
      image = create(:alert_metric_image, alert: alert)
      image_2 = create(:alert_metric_image, alert: alert)

      incident = execute.payload[:issue]

      expect(incident.metric_images.count).to eq(2)

      first_metric_image, second_metric_image = incident.metric_images.order(:created_at)

      expect_image_matches(first_metric_image, image)
      expect_image_matches(second_metric_image, image_2)
    end

    context 'when there are no metric images to copy' do
      it 'has no images' do
        incident = execute.payload[:issue]

        expect(incident.metric_images.count).to eq(0)
      end
    end

    private

    def expect_image_matches(image, image_expectation)
      expect(image.url).to eq(image_expectation.url)
      expect(image.url_text).to eq(image_expectation.url_text)
      expect(image.filename).to eq(image_expectation.filename)
      expect(image.file).not_to eq(image_expectation.file)
    end
  end
end
