# frozen_string_literal: true

require_relative '../../../../db/seeds/shared/dora_metrics'

module Quality
  module Seeders
    module Insights
      class Issues < Seeders::Issues
        TEAM_LABELS = %w[Plan Create Manage Verify Secure].freeze
        TYPE_LABELS = %w[bug feature].freeze
        SEVERITY_LABELS = %w[S::1 S::2 S::3 S::4].freeze
        PRIORITY_LABELS = %w[P::1 P::2 P::3 P::4].freeze

        def seed(backfill_weeks: DEFAULT_BACKFILL_WEEKS, average_issues_per_week: DEFAULT_AVERAGE_ISSUES_PER_WEEK)
          create_iterations!

          ::Gitlab::Seeder::DoraMetrics.new(project: project).execute

          super
        end

        private

        def additional_params
          {
            weight: rand(10),
            iteration_id: random_iteration_id
          }
        end

        def random_iteration_id
          return unless project.group

          project.group.iterations.sample&.id
        end

        def create_iterations!
          return unless project.group

          3.times do |i|
            FactoryBot.create(:iteration, group: project.group, title: "it-#{i}-#{suffix}")
          end
        end

        def labels
          super + [
            TEAM_LABELS.sample,
            TYPE_LABELS.sample,
            SEVERITY_LABELS.sample,
            PRIORITY_LABELS.sample
          ]
        end
      end
    end
  end
end
