# frozen_string_literal: true

require 'devfile'

module RemoteDevelopment
  module Workspaces
    module Reconcile
      # noinspection RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
      class DevfileParser
        # @param [String] processed_devfile
        # @param [String] name
        # @param [String] namespace
        # @param [Integer] replicas
        # @param [String] domain_template
        # @param [Hash] labels
        # @param [Hash] annotations
        # @param [User] user
        # @return [Array<Hash>]
        def get_all(processed_devfile:, name:, namespace:, replicas:, domain_template:, labels:, annotations:, user:)
          begin
            workspace_resources_yaml = Devfile::Parser.get_all(
              processed_devfile,
              name,
              namespace,
              YAML.dump(labels.deep_stringify_keys),
              YAML.dump(annotations.deep_stringify_keys),
              replicas,
              domain_template,
              'none'
            )
          rescue Devfile::CliError => e
            logger.warn(
              message: 'Error parsing devfile with Devfile::Parser.get_all',
              error_type: 'reconcile_devfile_parser_error',
              workspace_name: name,
              workspace_namespace: namespace,
              devfile_parser_error: e.message
            )
            return []
          end

          workspace_resources = YAML.load_stream(workspace_resources_yaml)
          workspace_resources = set_security_context(workspace_resources: workspace_resources)
          workspace_resources = set_git_configuration(workspace_resources: workspace_resources, user: user)
          set_workspace_environment_variables(
            workspace_resources: workspace_resources,
            domain_template: domain_template
          )
        end

        private

        # @return [RemoteDevelopment::Logger]
        def logger
          @logger ||= RemoteDevelopment::Logger.build
        end

        # Devfile library allows specifying the security context of pods/containers as mentioned in
        # https://github.com/devfile/api/issues/920 through `pod-overrides` and `container-overrides` attributes.
        # However, https://github.com/devfile/library/pull/158 which is implementing this feature,
        # is not part of v2.2.0 which is the latest release of the devfile which is being used in the devfile-gem.
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409189
        #       Once devfile library releases a new version, update the devfile-gem and
        #       move the logic of setting the security context in the `devfile_processor` as part of workspace creation.
        RUN_AS_USER = 5001

        # @param [Array<Hash>] workspace_resources
        # @return [Array<Hash>]
        def set_security_context(workspace_resources:)
          workspace_resources.each do |workspace_resource|
            next unless workspace_resource['kind'] == 'Deployment'

            pod_spec = workspace_resource['spec']['template']['spec']
            # Explicitly set security context for the pod
            pod_spec['securityContext'] = {
              'runAsNonRoot' => true,
              'runAsUser' => RUN_AS_USER,
              'fsGroup' => 0,
              'fsGroupChangePolicy' => 'OnRootMismatch'
            }
            # Explicitly set security context for all containers
            pod_spec['containers'].each do |container|
              container['securityContext'] = {
                'allowPrivilegeEscalation' => false,
                'privileged' => false,
                'runAsNonRoot' => true,
                'runAsUser' => RUN_AS_USER
              }
            end
            # Explicitly set security context for all init containers
            pod_spec['initContainers'].each do |init_container|
              init_container['securityContext'] = {
                'allowPrivilegeEscalation' => false,
                'privileged' => false,
                'runAsNonRoot' => true,
                'runAsUser' => RUN_AS_USER
              }
            end
          end
          workspace_resources
        end

        # @param [Array<Hash>] workspace_resources
        # @param [User] user
        # @return [Array<Hash>]
        def set_git_configuration(workspace_resources:, user:)
          workspace_resources.each do |workspace_resource|
            next unless workspace_resource.fetch('kind') == 'Deployment'

            # Set git configuration for the `gl-cloner-injector-*`
            pod_spec = workspace_resource.fetch('spec').fetch('template').fetch('spec')
            pod_spec.fetch('initContainers').each do |init_container|
              next unless init_container.fetch('name').starts_with?('gl-cloner-injector-')

              init_container.fetch('env').concat([
                {
                  'name' => 'GIT_AUTHOR_NAME',
                  'value' => user.name
                },
                {
                  'name' => 'GIT_AUTHOR_EMAIL',
                  'value' => user.email
                }
              ])
            end
          end
          workspace_resources
        end

        # @param [Array<Hash>] workspace_resources
        # @param [String] domain_template
        # @return [Array<Hash>]
        def set_workspace_environment_variables(workspace_resources:, domain_template:)
          env_variables = [
            {
              'name' => 'GL_WORKSPACE_DOMAIN_TEMPLATE',
              'value' => domain_template.sub(/{{.port}}/, "${PORT}")
            }
          ]
          workspace_resources.each do |workspace_resource|
            next unless workspace_resource['kind'] == 'Deployment'

            pod_spec = workspace_resource['spec']['template']['spec']

            pod_spec['initContainers'].each do |init_containers|
              init_containers.fetch('env').concat(env_variables)
            end

            pod_spec['containers'].each do |container|
              container.fetch('env').concat(env_variables)
            end
          end
          workspace_resources
        end
      end
    end
  end
end
