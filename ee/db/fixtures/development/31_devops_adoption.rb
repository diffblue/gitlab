# frozen_string_literal: true

Gitlab::Seeder.quiet do
  groups = Group.not_mass_generated.take(5)

  next if groups.empty?

  groups = groups.sample(2)

  ActiveRecord::Base.transaction do
    enabled_namespaces = [
      Analytics::DevopsAdoption::EnabledNamespace.create(namespace: groups.first, display_namespace: groups.first),
      Analytics::DevopsAdoption::EnabledNamespace.create(namespace: groups.last, display_namespace: groups.last)
    ]

    if enabled_namespaces.any?(&:invalid?)
      puts "Error creating enabled_namespaces"
      puts enabled_namespaces.map(&:errors).to_s
      next
    end

    booleans = [true, false]

    # create snapshots for the last 5 months
    4.downto(0).each do |index|
      end_time = index.months.ago.at_end_of_month

      enabled_namespaces.each do |enabled_namespace|
        calculated_data = {
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

        Analytics::DevopsAdoption::Snapshots::CreateService.new(params: calculated_data).execute
      end
    end

    print '.'
  end
end
