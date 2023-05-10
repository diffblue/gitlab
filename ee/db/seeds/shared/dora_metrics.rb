# frozen_string_literal: true

class Gitlab::Seeder::DoraMetrics # rubocop:disable Style/ClassAndModuleChildren
  def initialize(project: nil)
    @project = project || create_new_project
    @environment = @project.environments.find_by_name('production')
    @environment ||= FactoryBot.create(:environment, name: 'production', project: @project)
  end

  def execute
    create_dora_metrics

    puts "Successfully seeded DORA metrics for '#{@project.full_path}'!"
    puts "URL: #{Rails.application.routes.url_helpers.project_url(@project)}"
  end

  private

  def create_new_project
    namespace = FactoryBot.create(
      :group,
      name: "Value Stream Management Group DORA #{suffix}",
      path: "vsmg-#{suffix}"
    )

    FactoryBot.create(
      :project,
      :repository,
      name: "Value Stream Management Project DORA #{suffix}",
      path: "vsmp-#{suffix}",
      creator: admin,
      namespace: namespace
    )
  end

  def create_dora_metrics
    100.times do |i|
      Dora::DailyMetrics.create(
        environment_id: @environment.id,
        date: (i + 1).days.ago,
        deployment_frequency: rand(50),
        incidents_count: rand(5),
        lead_time_for_changes_in_seconds: rand(50000),
        time_to_restore_service_in_seconds: rand(100000))
    end
  end

  def suffix
    @suffix ||= Time.now.to_i
  end

  def admin
    @admin ||= User.admins.first
  end
end
