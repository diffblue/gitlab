# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      # noinspection RubyResolve
      class CreateProcessor
        include States

        def process(params:)
          agent = params.fetch(:agent)
          unless agent.remote_development_agent_config
            return nil, Error.new(
              message: "No RemoteDevelopmentAgentConfig found for agent '#{agent.name}'",
              reason: :bad_request
            )
          end

          project = params.fetch(:project)
          devfile_ref = params.fetch(:devfile_ref)
          devfile_path = params.fetch(:devfile_path)
          repository = project.repository
          devfile = repository.blob_at_branch(devfile_ref, devfile_path)&.data

          unless devfile
            error = Error.new(message: 'Devfile not found in project', reason: :bad_request)
            return nil, error
          end

          # workspace_root is set to /projects as devfile parser uses this value when setting env vars
          # PROJECTS_ROOT and PROJECT_SOURCE that are available within the spawned containers
          # hence, workspace_root will be used across containers/initContainers as the place for user data
          #
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/408450
          #       explore in depth implications of PROJECTS_ROOT and PROJECT_SOURCE env vars with devfile team
          #       and update devfile processing to use them idiomatically / conform to devfile specifications
          workspace_root = "/projects"

          begin
            processed_devfile = DevfileProcessor.new.process(
              devfile: devfile,
              editor: params.fetch(:editor),
              project: project,
              workspace_root: workspace_root
            )
          # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
          #       handle other errors that can occurs apart from the ArgumentError raised from devfile_validator.rb
          rescue ArgumentError => e
            # Return early if any errors are detected with processing(and validating) the devfile
            error = Error.new(message: "Invalid devfile: #{e.message}", reason: :bad_request)
            return nil, error
          end

          workspace = project.workspaces.build(params)

          workspace.devfile = devfile
          workspace.processed_devfile = processed_devfile
          workspace.actual_state = CREATION_REQUESTED

          user = params.fetch(:user)
          random_string = SecureRandom.alphanumeric(6).downcase
          workspace.namespace = "gl-rd-ns-#{agent.id}-#{user.id}-#{random_string}"
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409774
          #       We can come maybe come up with a better/cooler way to get a unique name, for now this works
          workspace.name = "workspace-#{agent.id}-#{user.id}-#{random_string}"

          project_dir = "#{workspace_root}/#{project.path}"
          workspace_host = "60001-#{workspace.name}.#{workspace.dns_zone}"
          workspace.url = URI::HTTPS.build({
            host: workspace_host,
            query: {
              folder: project_dir
            }.to_query
          }).to_s

          workspace.save!

          payload = { workspace: workspace }
          [payload, nil]
        end
      end
    end
  end
end
