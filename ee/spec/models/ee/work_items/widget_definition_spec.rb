# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WidgetDefinition, feature_category: :team_planning do
  describe '.available_widgets' do
    subject { described_class.available_widgets }

    it 'returns list of all possible widgets' do
      is_expected.to contain_exactly(
        ::WorkItems::Widgets::Description,
        ::WorkItems::Widgets::Hierarchy,
        ::WorkItems::Widgets::Iteration,
        ::WorkItems::Widgets::Labels,
        ::WorkItems::Widgets::Assignees,
        ::WorkItems::Widgets::Weight,
        ::WorkItems::Widgets::StartAndDueDate,
        ::WorkItems::Widgets::Status,
        ::WorkItems::Widgets::HealthStatus,
        ::WorkItems::Widgets::Milestone,
        ::WorkItems::Widgets::Notes,
        ::WorkItems::Widgets::Progress,
        ::WorkItems::Widgets::RequirementLegacy,
        ::WorkItems::Widgets::TestReports,
        ::WorkItems::Widgets::Notifications,
        ::WorkItems::Widgets::CurrentUserTodos,
        ::WorkItems::Widgets::AwardEmoji
      )
    end
  end
end
