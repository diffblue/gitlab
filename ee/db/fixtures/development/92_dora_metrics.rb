# frozen_string_literal: true

# Usage:
#
# Simple invocation always creates a new project:
#
# SEED_DORA=1 FILTER=dora_metrics bundle exec rake db:seed_fu
#
#
# Run for an existing project
#
# SEED_DORA=1  PROJECT_ID=10 FILTER=dora_metrics bundle exec rake db:seed_fu

require './ee/db/seeds/shared/dora_metrics'

# rubocop:disable Rails/Output
Gitlab::Seeder.quiet do
  flag = ENV['SEED_DORA']

  unless flag
    puts "Skipped. Use the SEED_DORA=1 environment variable to enable."
    next
  end

  project_id = ENV['PROJECT_ID']
  project = Project.find(project_id) if project_id

  seeder = Gitlab::Seeder::DoraMetrics.new(project: project)

  seeder.execute
end
# rubocop:enable Rails/Output
