# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Statistics::ScheduleWorker, feature_category: :vulnerability_management do
  let(:worker) { described_class.new }

  describe "#perform" do
    let(:project) { create(:project) }
    let(:deleted_project) { create(:project, pending_delete: true) }

    before do
      project.project_setting.update!(has_vulnerabilities: true)
      deleted_project.project_setting.update!(has_vulnerabilities: true)

      allow(Vulnerabilities::Statistics::AdjustmentWorker).to receive(:perform_in)
    end

    it 'schedules the AdjustmentWorker with project_ids' do
      worker.perform

      expect(Vulnerabilities::Statistics::AdjustmentWorker).to have_received(:perform_in).with(30, [project.id])
    end
  end
end
