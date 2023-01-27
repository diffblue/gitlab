# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::WidgetInterface do
  include GraphqlHelpers

  describe ".resolve_type" do
    using RSpec::Parameterized::TableSyntax

    where(:widget_class, :widget_type_name) do
      WorkItems::Widgets::Status             | Types::WorkItems::Widgets::StatusType
      WorkItems::Widgets::Weight             | Types::WorkItems::Widgets::WeightType
      WorkItems::Widgets::HealthStatus       | Types::WorkItems::Widgets::HealthStatusType
      WorkItems::Widgets::Progress           | Types::WorkItems::Widgets::ProgressType
      WorkItems::Widgets::RequirementLegacy  | Types::WorkItems::Widgets::RequirementLegacyType
      WorkItems::Widgets::TestReports        | Types::WorkItems::Widgets::TestReportsType
    end

    with_them do
      it 'knows the correct type for objects' do
        expect(
          described_class.resolve_type(widget_class.new(build(:work_item)), {})
        ).to eq(widget_type_name)
      end
    end

    it 'raises an error for an unknown type' do
      project = build(:project)

      expect { described_class.resolve_type(project, {}) }
        .to raise_error("Unknown GraphQL type for widget #{project}")
    end
  end
end
