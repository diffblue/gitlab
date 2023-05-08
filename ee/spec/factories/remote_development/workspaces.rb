# frozen_string_literal: true

FactoryBot.define do
  factory :workspace, class: 'RemoteDevelopment::Workspace' do
    # noinspection RailsParamDefResolve
    project factory: [:project, :public, :in_group]
    user
    agent factory: [:ee_cluster_agent, :with_remote_development_agent_config]

    random_string = SecureRandom.alphanumeric(6).downcase
    name { "workspace-#{agent.id}-#{user.id}-#{random_string}" }

    add_attribute(:namespace) { "gl-rd-ns-#{agent.id}-#{user.id}-#{random_string}" }

    desired_state { RemoteDevelopment::Workspaces::States::STOPPED }
    actual_state { RemoteDevelopment::Workspaces::States::STOPPED }
    deployment_resource_version { 2 }
    editor { 'webide' }
    # noinspection RubyResolve
    max_hours_before_termination { 24 }

    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409779
    #       Can we make factorybot retrieve the dns_zone from the agent's remote_development_agent_config
    #       so we can interpolate it here and ensure it is consistent?
    url { "https://60001-#{name}.workspaces.localdev.me" }

    # noinspection RubyResolve
    devfile_ref { 'main' }
    # noinspection RubyResolve
    devfile_path { '.devfile.yaml' }

    # noinspection RubyResolve
    devfile do
      # noinspection RubyMismatchedArgumentType
      File.read(Rails.root.join('ee/spec/fixtures/remote_development/example.devfile.yaml'))
    end

    # noinspection RubyResolve
    processed_devfile do
      # noinspection RubyMismatchedArgumentType
      File.read(Rails.root.join('ee/spec/fixtures/remote_development/example.processed-devfile.yaml'))
    end

    transient do
      # noinspection RubyResolve
      skip_realistic_after_create_timestamp_updates { false }
    end

    # Use this trait if you want to directly control any timestamp fields when invoking the factory.
    trait :without_realistic_after_create_timestamp_updates do
      transient do
        # noinspection RubyResolve
        skip_realistic_after_create_timestamp_updates { true }
      end
    end

    after(:build) do |workspace, _|
      user = workspace.user
      workspace.project.add_developer(user)
      workspace.agent.project.add_developer(user)
    end

    after(:create) do |workspace, evaluator|
      # noinspection RubyResolve
      if evaluator.skip_realistic_after_create_timestamp_updates
        # noinspection RubyResolve
        # Set responded_to_agent_at to a non-nil value unless it has already been set
        workspace.update!(responded_to_agent_at: workspace.updated_at) unless workspace.responded_to_agent_at
      else
        if workspace.desired_state == workspace.actual_state
          # The most recent activity was a poll that reconciled the desired and actual state.
          desired_state_updated_at = 2.seconds.ago
          responded_to_agent_at = 1.second.ago
        else
          # The most recent activity was a user action which updated the desired state to be different
          # than the actual state.
          desired_state_updated_at = 1.second.ago
          responded_to_agent_at = 2.seconds.ago
        end

        workspace.update!(
          # NOTE: created_at and updated_at are not currently used in any logic, but we set them to be
          #       before desired_state_updated_at or responded_to_agent_at to ensure the record represents
          #       a realistic condition.
          created_at: 3.seconds.ago,
          updated_at: 3.seconds.ago,

          desired_state_updated_at: desired_state_updated_at,
          responded_to_agent_at: responded_to_agent_at
        )
      end
    end

    trait :unprovisioned do
      desired_state { RemoteDevelopment::Workspaces::States::RUNNING }
      actual_state { RemoteDevelopment::Workspaces::States::CREATION_REQUESTED }
      # noinspection RubyResolve
      responded_to_agent_at { nil }
      deployment_resource_version { nil }
    end
  end
end
