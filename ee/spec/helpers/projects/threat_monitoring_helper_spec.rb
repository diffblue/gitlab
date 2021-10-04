# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ThreatMonitoringHelper do
  let(:project) { create(:project, :repository, :public) }

  describe '#threat_monitoring_alert_details_data' do
    let(:alert) { build(:alert_management_alert, project: project) }

    context 'when a new alert is created' do
      subject { helper.threat_monitoring_alert_details_data(project, alert.iid) }

      it 'returns expected alert data' do
        expect(subject).to match({
          'alert-id' => alert.iid,
          'project-path' => project.full_path,
          'project-id' => project.id,
          'project-issues-path' => project_issues_path(project),
          'page' => 'THREAT_MONITORING'
        })
      end
    end
  end
end
