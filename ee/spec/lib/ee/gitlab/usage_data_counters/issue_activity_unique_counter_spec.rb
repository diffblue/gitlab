# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::IssueActivityUniqueCounter, :snowplow, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }
  let(:project) { create(:project) }
  let(:namespace) { project&.namespace }

  context 'for Issue health status changed actions' do
    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::ISSUE_HEALTH_STATUS_CHANGED }

      subject(:track_event) { described_class.track_issue_health_status_changed_action(author: user, project: project) }
    end
  end

  context 'for Issue iteration changed actions' do
    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::ISSUE_ITERATION_CHANGED }

      subject(:track_event) { described_class.track_issue_iteration_changed_action(author: user, project: project) }
    end
  end

  context 'for Issue weight changed actions' do
    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::ISSUE_WEIGHT_CHANGED }

      subject(:track_event) { described_class.track_issue_weight_changed_action(author: user, project: project) }
    end
  end

  context 'for Issue added to epic actions' do
    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::ISSUE_ADDED_TO_EPIC }

      subject(:track_event) { described_class.track_issue_added_to_epic_action(author: user, project: project) }
    end
  end

  context 'for Issue removed from epic actions' do
    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::ISSUE_REMOVED_FROM_EPIC }

      subject(:track_event) { described_class.track_issue_removed_from_epic_action(author: user, project: project) }
    end
  end

  context 'for Issue changed epic actions' do
    it_behaves_like 'internal event tracking' do
      let(:event) { described_class::ISSUE_CHANGED_EPIC }

      subject(:track_event) { described_class.track_issue_changed_epic_action(author: user, project: project) }
    end
  end
end
