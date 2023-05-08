# frozen_string_literal: true

require 'devfile'

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class DevfileParser
        def get_all(processed_devfile:, name:, namespace:, replicas:, domain_template:, labels:, annotations:)
          workspace_resources_yaml = Devfile::Parser.get_all(
            processed_devfile,
            name,
            namespace,
            YAML.dump(labels),
            YAML.dump(annotations),
            replicas,
            domain_template,
            'none'
          )
          workspace_resources = YAML.load_stream(workspace_resources_yaml)
          set_security_context(workspace_resources: workspace_resources)
        end

        private

        # Devfile library allows specifying the security context of pods/containers as mentioned in
        # https://github.com/devfile/api/issues/920 through `pod-overrides` and `container-overrides` attributes.
        # However, https://github.com/devfile/library/pull/158 which is implementing this feature,
        # is not part of v2.2.0 which is the latest release of the devfile which is being used in the devfile-gem.
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409189
        #       Once devfile library releases a new version, update the devfile-gem and
        #       move the logic of setting the security context in the `devfile_processor` as part of workspace creation.
        RUN_AS_USER = 5001

        def set_security_context(workspace_resources:)
          workspace_resources.each do |workspace_resource|
            next unless workspace_resource['kind'] == 'Deployment'

            pod_spec = workspace_resource['spec']['template']['spec']
            # Explicitly set security context for the pod
            pod_spec['securityContext'] = {
              'runAsNonRoot' => true,
              'runAsUser' => RUN_AS_USER
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
      end
    end
  end
end
