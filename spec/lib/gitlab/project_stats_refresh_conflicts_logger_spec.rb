# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ProjectStatsRefreshConflictsLogger do
  describe '.warn_artifact_deletion_during_stats_refresh' do
    it 'logs a warning about artifacts being deleted while the project is undergoing stats refresh' do
      project_id = 123
      method = 'Foo#action'

      payload = Gitlab::ApplicationContext.current.merge(
        message: 'Deleted artifacts undergoing refresh',
        method: method,
        project_id: project_id
      )

      expect(Gitlab::AppLogger).to receive(:warn).with(payload)

      described_class.warn_artifact_deletion_during_stats_refresh(project_id: project_id, method: method)
    end
  end
end
