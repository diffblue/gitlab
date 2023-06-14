# frozen_string_literal: true

# Usage:
#
# Simple invocation always takes two existing groups
#
# FILTER=devops_adoption bundle exec rake db:seed_fu
#
# Run for a predefined existing group
#
# FILTER=devops_adoption DEVOPS_GROUP_ID=9 bundle exec rake db:seed_fu
class Gitlab::Seeder::DevopsAdoption # rubocop:disable Style/ClassAndModuleChildren
  attr_reader :groups

  def initialize(group: nil)
    @groups = [group] if group
    @groups ||= Group.not_mass_generated.sample(2)
  end

  def admin
    @admin ||= User.admins.first
  end

  def seed!
    groups.each do |group|
      enabled_namespace = Analytics::DevopsAdoption::EnabledNamespace.find_or_initialize_by(namespace: group)

      if enabled_namespace.new_record?
        enabled_namespace.display_namespace = group
        enabled_namespace.save!
      end

      if enabled_namespace.invalid?
        puts "Error creating enabled_namespaces"
        puts enabled_namespaces.map(&:errors).to_s
        next
      end

      # create snapshots for the last 5 months
      4.downto(0).each do |index|
        end_time = index.months.ago.at_end_of_month
        calculated_data = generate_calculated_data_for(enabled_namespace, end_time)

        Analytics::DevopsAdoption::Snapshots::CreateService.new(params: calculated_data).execute
      end

      puts "Successfully seeded '#{group.full_path}' for Devops adoption!"
      puts "URL: #{Rails.application.routes.url_helpers.group_url(group)}"
    end
  end

  def generate_calculated_data_for(enabled_namespace, end_time)
    booleans = [true, false]

    {
      namespace: enabled_namespace.namespace,
      issue_opened: booleans.sample,
      merge_request_opened: booleans.sample,
      merge_request_approved: booleans.sample,
      runner_configured: booleans.sample,
      pipeline_succeeded: booleans.sample,
      deploy_succeeded: booleans.sample,
      code_owners_used_count: rand(10),
      sast_enabled_count: rand(10),
      dast_enabled_count: rand(10),
      total_projects_count: rand(10..19),
      recorded_at: [end_time + 1.day, Time.zone.now].min,
      end_time: end_time
    }
  end
end

Gitlab::Seeder.quiet do
  group_id = ENV['DEVOPS_GROUP_ID']
  group = Group.find(group_id) if group_id

  Gitlab::Seeder::DevopsAdoption.new(group: group).seed!
end
