# frozen_string_literal: true

RSpec.shared_context 'with remote development shared fixtures' do
  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Layout/LineLength
  # noinspection RubyInstanceMethodNamingConvention, RubyLocalVariableNamingConvention, RubyParameterNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  # rubocop:enable Layout/LineLength
  def create_workspace_agent_info_hash(
    workspace:,
    # NOTE: previous_actual_state is the actual state of the workspace IMMEDIATELY prior to the current state. We don't
    # simulate the situation where there may have been multiple transitions between reconciliation polling intervals.
    previous_actual_state:,
    current_actual_state:,
    # NOTE: workspace_exists is whether the workspace exists in the cluster at the time of the current_actual_state.
    workspace_exists:,
    workspace_variables_env_var: nil,
    workspace_variables_file: nil,
    resource_version: '1',
    dns_zone: 'workspaces.localdev.me',
    error_details: nil
  )
    info = {
      name: workspace.name,
      namespace: workspace.namespace
    }

    if current_actual_state == RemoteDevelopment::Workspaces::States::TERMINATED
      info[:termination_progress] =
        RemoteDevelopment::Workspaces::States::TERMINATED
    end

    if current_actual_state == RemoteDevelopment::Workspaces::States::TERMINATING
      info[:termination_progress] =
        RemoteDevelopment::Workspaces::States::TERMINATING
    end

    if [
      RemoteDevelopment::Workspaces::States::TERMINATING,
      RemoteDevelopment::Workspaces::States::TERMINATED,
      RemoteDevelopment::Workspaces::States::UNKNOWN
    ].include?(current_actual_state)
      return info
    end

    spec_replicas =
      if [RemoteDevelopment::Workspaces::States::STOPPED, RemoteDevelopment::Workspaces::States::STOPPING]
           .include?(current_actual_state)
        0
      else
        1
      end

    started = spec_replicas == 1

    # rubocop:disable Lint/DuplicateBranch
    status =
      case [previous_actual_state, current_actual_state, workspace_exists]
      in [RemoteDevelopment::Workspaces::States::CREATION_REQUESTED, RemoteDevelopment::Workspaces::States::STARTING, _]
        <<~STATUS_YAML
          conditions:
          - lastTransitionTime: "2023-04-10T10:14:14Z"
            lastUpdateTime: "2023-04-10T10:14:14Z"
            message: Created new replica set "#{workspace.name}-hash"
            reason: NewReplicaSetCreated
            status: "True"
            type: Progressing
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::STARTING, false]
        <<~STATUS_YAML
          conditions:
          - lastTransitionTime: "2023-04-10T10:14:14Z"
            lastUpdateTime: "2023-04-10T10:14:14Z"
            message: Deployment does not have minimum availability.
            reason: MinimumReplicasUnavailable
            status: "False"
            type: Available
          - lastTransitionTime: "2023-04-10T10:14:14Z"
            lastUpdateTime: "2023-04-10T10:14:14Z"
            message: ReplicaSet "#{workspace.name}-hash" is progressing.
            reason: ReplicaSetUpdated
            status: "True"
            type: Progressing
          observedGeneration: 1
          replicas: 1
          unavailableReplicas: 1
          updatedReplicas: 1
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::RUNNING, false]
        <<~STATUS_YAML
          availableReplicas: 1
          conditions:
          - lastTransitionTime: "2023-03-06T14:36:36Z"
            lastUpdateTime: "2023-03-06T14:36:36Z"
            message: Deployment has minimum availability.
            reason: MinimumReplicasAvailable
            status: "True"
            type: Available
          - lastTransitionTime: "2023-03-06T14:36:31Z"
            lastUpdateTime: "2023-03-06T14:36:36Z"
            message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
            reason: NewReplicaSetAvailable
            status: "True"
            type: Progressing
          readyReplicas: 1
          replicas: 1
          updatedReplicas: 1
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::FAILED, false]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::FAILED, RemoteDevelopment::Workspaces::States::STARTING, false]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::RUNNING, RemoteDevelopment::Workspaces::States::FAILED, _]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::RUNNING, RemoteDevelopment::Workspaces::States::STOPPING, _]
        <<~STATUS_YAML
          availableReplicas: 1
          conditions:
          - lastTransitionTime: "2023-04-10T10:40:35Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: Deployment has minimum availability.
            reason: MinimumReplicasAvailable
            status: "True"
            type: Available
          - lastTransitionTime: "2023-04-10T10:40:24Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
            reason: NewReplicaSetAvailable
            status: "True"
            type: Progressing
          observedGeneration: 1
          readyReplicas: 1
          replicas: 1
          updatedReplicas: 1
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STOPPING, RemoteDevelopment::Workspaces::States::STOPPED, _]
        <<~STATUS_YAML
          conditions:
          - lastTransitionTime: "2023-04-10T10:40:35Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: Deployment has minimum availability.
            reason: MinimumReplicasAvailable
            status: "True"
            type: Available
          - lastTransitionTime: "2023-04-10T10:40:24Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
            reason: NewReplicaSetAvailable
            status: "True"
            type: Progressing
          observedGeneration: 2
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STOPPING, RemoteDevelopment::Workspaces::States::FAILED, _]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::STOPPED, RemoteDevelopment::Workspaces::States::STARTING, _]
        # There are multiple state transitions inside kubernetes
        # Fields like `replicas`, `unavailableReplicas` and `updatedReplicas` eventually become present
        <<~STATUS_YAML
          conditions:
          - lastTransitionTime: "2023-04-10T10:40:24Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
            reason: NewReplicaSetAvailable
            status: "True"
            type: Progressing
          - lastTransitionTime: "2023-04-10T10:49:59Z"
            lastUpdateTime: "2023-04-10T10:49:59Z"
            message: Deployment does not have minimum availability.
            reason: MinimumReplicasUnavailable
            status: "False"
            type: Available
          observedGeneration: 3
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STOPPED, RemoteDevelopment::Workspaces::States::FAILED, _]
        # Stopped workspace is terminated by the user which results in a Failed actual state.
        # e.g. could not unmount volume and terminate the workspace
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::STARTING, true]
        # There are multiple state transitions inside kubernetes
        # Fields like `replicas`, `unavailableReplicas` and `updatedReplicas` eventually become present
        <<~STATUS_YAML
          conditions:
          - lastTransitionTime: "2023-04-10T10:40:24Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
            reason: NewReplicaSetAvailable
            status: "True"
            type: Progressing
          - lastTransitionTime: "2023-04-10T10:49:59Z"
            lastUpdateTime: "2023-04-10T10:49:59Z"
            message: Deployment does not have minimum availability.
            reason: MinimumReplicasUnavailable
            status: "False"
            type: Available
          observedGeneration: 3
          replicas: 1
          unavailableReplicas: 1
          updatedReplicas: 1
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::RUNNING, true]
        <<~STATUS_YAML
          availableReplicas: 1
          conditions:
          - lastTransitionTime: "2023-04-10T10:40:24Z"
            lastUpdateTime: "2023-04-10T10:40:35Z"
            message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
            reason: NewReplicaSetAvailable
            status: "True"
            type: Progressing
          - lastTransitionTime: "2023-04-10T10:50:10Z"
            lastUpdateTime: "2023-04-10T10:50:10Z"
            message: Deployment has minimum availability.
            reason: MinimumReplicasAvailable
            status: "True"
            type: Available
          observedGeneration: 3
          readyReplicas: 1
          replicas: 1
          updatedReplicas: 1
        STATUS_YAML
      in [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::FAILED, true]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::FAILED, RemoteDevelopment::Workspaces::States::STARTING, true]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [RemoteDevelopment::Workspaces::States::FAILED, RemoteDevelopment::Workspaces::States::STOPPING, _]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
      in [_, RemoteDevelopment::Workspaces::States::FAILED, _]
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
        # <<~STATUS_YAML
        #   conditions:
        #     - lastTransitionTime: "2023-03-06T14:36:31Z"
        #       lastUpdateTime: "2023-03-08T11:16:35Z"
        #       message: ReplicaSet "#{workspace.name}-hash" has successfully progressed.
        #       reason: NewReplicaSetAvailable
        #       status: "True"
        #       type: Progressing
        #     - lastTransitionTime: "2023-03-08T11:16:55Z"
        #       lastUpdateTime: "2023-03-08T11:16:55Z"
        #       message: Deployment does not have minimum availability.
        #       reason: MinimumReplicasUnavailable
        #       status: "False"
        #       type: Available
        #     replicas: 1
        #     unavailableReplicas: 1
        #     updatedReplicas: 1
        # STATUS_YAML
      else
        msg =
          'Unsupported state transition passed for create_workspace_agent_info_hash fixture creation: ' \
            "actual_state: #{previous_actual_state} -> #{current_actual_state}, " \
            "existing_workspace: #{workspace_exists}"
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError, msg
      end
    # rubocop:enable Lint/DuplicateBranch

    config_to_apply_yaml = create_config_to_apply(
      workspace: workspace,
      workspace_variables_env_var: workspace_variables_env_var,
      workspace_variables_file: workspace_variables_file,
      started: started,
      include_inventory: false,
      include_network_policy: false,
      include_secrets: false,
      dns_zone: dns_zone
    )
    config_to_apply = YAML.load_stream(config_to_apply_yaml)
    latest_k8s_deployment_info = config_to_apply.detect { |config| config.fetch('kind') == 'Deployment' }
    latest_k8s_deployment_info['metadata']['resourceVersion'] = resource_version
    latest_k8s_deployment_info['status'] = YAML.safe_load(status)

    info[:latest_k8s_deployment_info] = latest_k8s_deployment_info
    info[:error_details] = error_details
    info.deep_symbolize_keys.to_h
  end

  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # noinspection RubyParameterNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  def create_workspace_rails_info(
    name:,
    namespace:,
    desired_state:,
    actual_state:,
    deployment_resource_version: nil,
    config_to_apply: nil
  )
    {
      name: name,
      namespace: namespace,
      desired_state: desired_state,
      actual_state: actual_state,
      deployment_resource_version: deployment_resource_version,
      config_to_apply: config_to_apply
    }.compact
  end

  # rubocop:disable Metrics/ParameterLists
  # noinspection RubyLocalVariableNamingConvention,RubyParameterNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  # rubocop:disable Metrics/AbcSize
  def create_config_to_apply(
    workspace:,
    started:,
    workspace_variables_env_var: nil,
    workspace_variables_file: nil,
    include_inventory: true,
    include_network_policy: true,
    include_secrets: false,
    dns_zone: 'workspaces.localdev.me'
  )
    spec_replicas = started == true ? 1 : 0
    host_template_annotation = get_workspace_host_template_annotation(workspace.name, dns_zone)

    workspace_inventory = workspace_inventory(
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: workspace.agent.id
    )

    workspace_deployment = workspace_deployment(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: workspace.agent.id,
      spec_replicas: spec_replicas,
      host_template_annotation: host_template_annotation
    )

    workspace_service = workspace_service(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: agent.id,
      host_template_annotation: host_template_annotation
    )

    workspace_pvc = workspace_pvc(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: workspace.agent.id,
      host_template_annotation: host_template_annotation
    )

    workspace_network_policy = workspace_network_policy(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: agent.id,
      host_template_annotation: host_template_annotation
    )

    workspace_secrets_inventory = workspace_secrets_inventory(
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: agent.id
    )

    workspace_secret_env_var = workspace_secret_env_var(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: agent.id,
      host_template_annotation: host_template_annotation,
      workspace_variables_env_var: workspace_variables_env_var || get_workspace_variables_env_var(
        workspace_variables: workspace.workspace_variables
      )
    )

    workspace_secret_file = workspace_secret_file(
      workspace_id: workspace.id,
      workspace_name: workspace.name,
      workspace_namespace: workspace.namespace,
      agent_id: agent.id,
      host_template_annotation: host_template_annotation,
      workspace_variables_file: workspace_variables_file || get_workspace_variables_file(
        workspace_variables: workspace.workspace_variables
      )
    )

    resources = []
    resources << workspace_inventory if include_inventory
    resources << workspace_deployment
    resources << workspace_service
    resources << workspace_pvc
    resources << workspace_network_policy if include_network_policy
    resources << workspace_secrets_inventory if include_secrets && include_inventory
    resources << workspace_secret_env_var if include_secrets
    resources << workspace_secret_file if include_secrets

    resources.map do |resource|
      YAML.dump(resource.deep_stringify_keys)
    end.join
  end
  # rubocop:enable Metrics/AbcSize

  def create_config_to_apply_prev1(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    started:,
    user_name:,
    user_email:,
    include_inventory: true,
    include_network_policy: true,
    dns_zone: 'workspaces.localdev.me'
  )
    spec_replicas = started == true ? 1 : 0
    host_template_annotation = get_workspace_host_template_annotation(workspace_name, dns_zone)
    host_template_environment_variable = get_workspace_host_template_env_var(workspace_name, dns_zone)

    workspace_inventory = workspace_inventory(
      workspace_name: workspace_name,
      workspace_namespace: workspace_namespace,
      agent_id: agent_id
    )

    workspace_deployment = workspace_deployment_prev1(
      workspace_id: workspace_id,
      workspace_name: workspace_name,
      workspace_namespace: workspace_namespace,
      agent_id: agent_id,
      spec_replicas: spec_replicas,
      host_template_annotation: host_template_annotation,
      host_template_environment_variable: host_template_environment_variable,
      user_name: user_name,
      user_email: user_email
    )

    workspace_service = workspace_service(
      workspace_id: workspace_id,
      workspace_name: workspace_name,
      workspace_namespace: workspace_namespace,
      agent_id: agent_id,
      host_template_annotation: host_template_annotation
    )

    workspace_pvc = workspace_pvc(
      workspace_id: workspace_id,
      workspace_name: workspace_name,
      workspace_namespace: workspace_namespace,
      agent_id: agent_id,
      host_template_annotation: host_template_annotation
    )

    workspace_network_policy = workspace_network_policy(
      workspace_id: workspace_id,
      workspace_name: workspace_name,
      workspace_namespace: workspace_namespace,
      agent_id: agent_id,
      host_template_annotation: host_template_annotation
    )

    resources = []
    resources << workspace_inventory if include_inventory
    resources << workspace_deployment
    resources << workspace_service
    resources << workspace_pvc
    resources << workspace_network_policy if include_network_policy

    resources.map do |resource|
      YAML.dump(resource.deep_stringify_keys)
    end.join
  end

  # rubocop:enable Metrics/ParameterLists

  def workspace_inventory(
    workspace_name:,
    workspace_namespace:,
    agent_id:
  )
    {
      kind: "ConfigMap",
      apiVersion: "v1",
      metadata: {
        name: "#{workspace_name}-workspace-inventory",
        namespace: workspace_namespace.to_s,
        labels: {
          "cli-utils.sigs.k8s.io/inventory-id": "#{workspace_name}-workspace-inventory",
          "agent.gitlab.com/id": agent_id.to_s
        }
      }
    }
  end

  def workspace_deployment(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    spec_replicas:,
    host_template_annotation:
  )
    variables_file_mount_path = RemoteDevelopment::Workspaces::FileMounts::VARIABLES_FILE_DIR
    {
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: {
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        },
        creationTimestamp: nil,
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        name: workspace_name.to_s,
        namespace: workspace_namespace.to_s
      },
      spec: {
        replicas: spec_replicas,
        selector: {
          matchLabels: {
            "agent.gitlab.com/id": agent_id.to_s
          }
        },
        strategy: {
          type: "Recreate"
        },
        template: {
          metadata: {
            annotations: {
              "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
              "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
              "workspaces.gitlab.com/id": workspace_id.to_s
            },
            creationTimestamp: nil,
            labels: {
              "agent.gitlab.com/id": agent_id.to_s
            },
            name: workspace_name.to_s,
            namespace: workspace_namespace.to_s
          },
          spec: {
            containers: [
              {
                command: [
                  "/projects/.gl-editor/start_server.sh"
                ],
                env: [
                  {
                    name: "EDITOR_VOLUME_DIR",
                    value: "/projects/.gl-editor"
                  },
                  {
                    name: "EDITOR_PORT",
                    value: "60001"
                  },
                  {
                    name: "SSH_PORT",
                    value: "60022"
                  },
                  {
                    name: "PROJECTS_ROOT",
                    value: "/projects"
                  },
                  {
                    name: "PROJECT_SOURCE",
                    value: "/projects"
                  }
                ],
                image: "quay.io/mloriedo/universal-developer-image:ubi8-dw-demo",
                imagePullPolicy: "Always",
                name: "tooling-container",
                ports: [
                  {
                    containerPort: 60001,
                    name: "editor-server",
                    protocol: "TCP"
                  },
                  {
                    containerPort: 60022,
                    name: "ssh-server",
                    protocol: "TCP"
                  }
                ],
                resources: {},
                volumeMounts: [
                  {
                    mountPath: "/projects",
                    name: "gl-workspace-data"
                  },
                  {
                    name: "gl-workspace-variables",
                    mountPath: variables_file_mount_path.to_s
                  }
                ],
                securityContext: {
                  allowPrivilegeEscalation: false,
                  privileged: false,
                  runAsNonRoot: true,
                  runAsUser: 5001
                },
                envFrom: [
                  {
                    secretRef: {
                      name: "#{workspace_name}-env-var"
                    }
                  }
                ]
              }
            ],
            initContainers: [
              {
                args: [
                  <<~ARGS.chomp
                    if [ ! -d '/projects/test-project' ];
                    then
                      git clone --branch master #{root_url}test-group/test-project.git /projects/test-project;
                    fi
                  ARGS
                ],
                command: %w[/bin/sh -c],
                env: [
                  {
                    name: "PROJECTS_ROOT",
                    value: "/projects"
                  },
                  {
                    name: "PROJECT_SOURCE",
                    value: "/projects"
                  }
                ],
                image: "alpine/git:2.36.3",
                imagePullPolicy: "Always",
                name: "gl-cloner-injector-gl-cloner-injector-command-1",
                resources: {
                  limits: {
                    cpu: "500m",
                    memory: "256Mi"
                  },
                  requests: {
                    cpu: "100m",
                    memory: "128Mi"
                  }
                },
                volumeMounts: [
                  {
                    mountPath: "/projects",
                    name: "gl-workspace-data"
                  },
                  {
                    name: "gl-workspace-variables",
                    mountPath: variables_file_mount_path.to_s
                  }
                ],
                securityContext: {
                  allowPrivilegeEscalation: false,
                  privileged: false,
                  runAsNonRoot: true,
                  runAsUser: 5001
                },
                envFrom: [
                  {
                    secretRef: {
                      name: "#{workspace_name}-env-var"
                    }
                  }
                ]
              },
              {
                env: [
                  {
                    name: "EDITOR_VOLUME_DIR",
                    value: "/projects/.gl-editor"
                  },
                  {
                    name: "EDITOR_PORT",
                    value: "60001"
                  },
                  {
                    name: "SSH_PORT",
                    value: "60022"
                  },
                  {
                    name: "PROJECTS_ROOT",
                    value: "/projects"
                  },
                  {
                    name: "PROJECT_SOURCE",
                    value: "/projects"
                  }
                ],
                image: "registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector:2",
                imagePullPolicy: "Always",
                name: "gl-editor-injector-gl-editor-injector-command-2",
                resources: {
                  limits: {
                    cpu: "500m",
                    memory: "256Mi"
                  },
                  requests: {
                    cpu: "100m",
                    memory: "128Mi"
                  }
                },
                volumeMounts: [
                  {
                    mountPath: "/projects",
                    name: "gl-workspace-data"
                  },
                  {
                    name: "gl-workspace-variables",
                    mountPath: variables_file_mount_path.to_s
                  }
                ],
                securityContext: {
                  allowPrivilegeEscalation: false,
                  privileged: false,
                  runAsNonRoot: true,
                  runAsUser: 5001
                },
                envFrom: [
                  {
                    secretRef: {
                      name: "#{workspace_name}-env-var"
                    }
                  }
                ]
              }
            ],
            volumes: [
              {
                name: "gl-workspace-data",
                persistentVolumeClaim: {
                  claimName: "#{workspace_name}-gl-workspace-data"
                }
              },
              {
                name: "gl-workspace-variables",
                projected: {
                  defaultMode: 508,
                  sources: [
                    {
                      secret: {
                        name: "#{workspace_name}-file"
                      }
                    }
                  ]
                }
              }
            ],
            securityContext: {
              runAsNonRoot: true,
              runAsUser: 5001,
              fsGroup: 0,
              fsGroupChangePolicy: "OnRootMismatch"
            }
          }
        }
      },
      status: {}
    }
  end

  # noinspection RubyParameterNamingConvention
  # rubocop:disable Metrics/ParameterLists
  def workspace_deployment_prev1(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    spec_replicas:,
    host_template_annotation:,
    host_template_environment_variable:,
    user_name:,
    user_email:
  )
    {
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: {
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        },
        creationTimestamp: nil,
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        name: workspace_name.to_s,
        namespace: workspace_namespace.to_s
      },
      spec: {
        replicas: spec_replicas,
        selector: {
          matchLabels: {
            "agent.gitlab.com/id": agent_id.to_s
          }
        },
        strategy: {
          type: "Recreate"
        },
        template: {
          metadata: {
            annotations: {
              "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
              "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
              "workspaces.gitlab.com/id": workspace_id.to_s
            },
            creationTimestamp: nil,
            labels: {
              "agent.gitlab.com/id": agent_id.to_s
            },
            name: workspace_name.to_s,
            namespace: workspace_namespace.to_s
          },
          spec: {
            containers: [
              {
                command: [
                  "/projects/.gl-editor/start_server.sh"
                ],
                env: [
                  {
                    name: "EDITOR_VOLUME_DIR",
                    value: "/projects/.gl-editor"
                  },
                  {
                    name: "EDITOR_PORT",
                    value: "60001"
                  },
                  {
                    name: "SSH_PORT",
                    value: "60022"
                  },
                  {
                    name: "PROJECTS_ROOT",
                    value: "/projects"
                  },
                  {
                    name: "PROJECT_SOURCE",
                    value: "/projects"
                  },
                  {
                    name: "GL_WORKSPACE_DOMAIN_TEMPLATE",
                    value: host_template_environment_variable.to_s
                  }
                ],
                image: "quay.io/mloriedo/universal-developer-image:ubi8-dw-demo",
                imagePullPolicy: "Always",
                name: "tooling-container",
                ports: [
                  {
                    containerPort: 60001,
                    name: "editor-server",
                    protocol: "TCP"
                  },
                  {
                    containerPort: 60022,
                    name: "ssh-server",
                    protocol: "TCP"
                  }
                ],
                resources: {},
                volumeMounts: [
                  {
                    mountPath: "/projects",
                    name: "gl-workspace-data"
                  }
                ],
                securityContext: {
                  allowPrivilegeEscalation: false,
                  privileged: false,
                  runAsNonRoot: true,
                  runAsUser: 5001
                }
              }
            ],
            initContainers: [
              {
                args: [
                  <<~ARGS.chomp
                    if [ ! -d '/projects/test-project' ];
                    then
                      git clone --branch master #{root_url}test-group/test-project.git /projects/test-project;
                      cd /projects/test-project;
                      git config user.name "${GIT_AUTHOR_NAME}";
                      git config user.email "${GIT_AUTHOR_EMAIL}";
                    fi
                  ARGS
                ],
                command: %w[/bin/sh -c],
                env: [
                  {
                    name: "PROJECTS_ROOT",
                    value: "/projects"
                  },
                  {
                    name: "PROJECT_SOURCE",
                    value: "/projects"
                  },
                  {
                    name: "GIT_AUTHOR_NAME",
                    value: user_name.to_s
                  },
                  {
                    name: "GIT_AUTHOR_EMAIL",
                    value: user_email.to_s
                  },
                  {
                    name: "GL_WORKSPACE_DOMAIN_TEMPLATE",
                    value: host_template_environment_variable.to_s
                  }
                ],
                image: "alpine/git:2.36.3",
                imagePullPolicy: "Always",
                name: "gl-cloner-injector-gl-cloner-injector-command-1",
                resources: {
                  limits: {
                    cpu: "500m",
                    memory: "256Mi"
                  },
                  requests: {
                    cpu: "100m",
                    memory: "128Mi"
                  }
                },
                volumeMounts: [
                  {
                    mountPath: "/projects",
                    name: "gl-workspace-data"
                  }
                ],
                securityContext: {
                  allowPrivilegeEscalation: false,
                  privileged: false,
                  runAsNonRoot: true,
                  runAsUser: 5001
                }
              },
              {
                env: [
                  {
                    name: "EDITOR_VOLUME_DIR",
                    value: "/projects/.gl-editor"
                  },
                  {
                    name: "EDITOR_PORT",
                    value: "60001"
                  },
                  {
                    name: "SSH_PORT",
                    value: "60022"
                  },
                  {
                    name: "PROJECTS_ROOT",
                    value: "/projects"
                  },
                  {
                    name: "PROJECT_SOURCE",
                    value: "/projects"
                  },
                  {
                    name: "GL_WORKSPACE_DOMAIN_TEMPLATE",
                    value: host_template_environment_variable.to_s
                  }
                ],
                image: "registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector:2",
                imagePullPolicy: "Always",
                name: "gl-editor-injector-gl-editor-injector-command-2",
                resources: {
                  limits: {
                    cpu: "500m",
                    memory: "256Mi"
                  },
                  requests: {
                    cpu: "100m",
                    memory: "128Mi"
                  }
                },
                volumeMounts: [
                  {
                    mountPath: "/projects",
                    name: "gl-workspace-data"
                  }
                ],
                securityContext: {
                  allowPrivilegeEscalation: false,
                  privileged: false,
                  runAsNonRoot: true,
                  runAsUser: 5001
                }
              }
            ],
            volumes: [
              {
                name: "gl-workspace-data",
                persistentVolumeClaim: {
                  claimName: "#{workspace_name}-gl-workspace-data"
                }
              }
            ],
            securityContext: {
              runAsNonRoot: true,
              runAsUser: 5001,
              fsGroup: 0,
              fsGroupChangePolicy: "OnRootMismatch"
            }
          }
        }
      },
      status: {}
    }
  end

  # rubocop:enable Metrics/ParameterLists

  def workspace_service(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    host_template_annotation:
  )
    {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        },
        creationTimestamp: nil,
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        name: workspace_name.to_s,
        namespace: workspace_namespace.to_s
      },
      spec: {
        ports: [
          {
            name: "editor-server",
            port: 60001,
            targetPort: 60001
          },
          {
            name: "ssh-server",
            port: 60022,
            targetPort: 60022
          }
        ],
        selector: {
          "agent.gitlab.com/id": agent_id.to_s
        }
      },
      status: {
        loadBalancer: {}
      }
    }
  end

  def workspace_pvc(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    host_template_annotation:
  )
    {
      apiVersion: "v1",
      kind: "PersistentVolumeClaim",
      metadata: {
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        },
        creationTimestamp: nil,
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        name: "#{workspace_name}-gl-workspace-data",
        namespace: workspace_namespace.to_s
      },
      spec: {
        accessModes: [
          "ReadWriteOnce"
        ],
        resources: {
          requests: {
            storage: "15Gi"
          }
        }
      },
      status: {}
    }
  end

  def workspace_network_policy(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    host_template_annotation:
  )
    {
      apiVersion: "networking.k8s.io/v1",
      kind: "NetworkPolicy",
      metadata: {
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-workspace-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        },
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        name: workspace_name.to_s,
        namespace: workspace_namespace.to_s
      },
      spec: {
        egress: [
          {
            to: [
              {
                ipBlock: {
                  cidr: "0.0.0.0/0",
                  except: %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16]
                }
              }
            ]
          },
          {
            ports: [
              {
                port: 53,
                protocol: "TCP"
              },
              {
                port: 53,
                protocol: "UDP"
              }
            ],
            to: [
              {
                namespaceSelector: {
                  matchLabels: {
                    "kubernetes.io/metadata.name": "kube-system"
                  }
                }
              }
            ]
          }
        ],
        ingress: [
          {
            from: [
              {
                namespaceSelector: {
                  matchLabels: {
                    "kubernetes.io/metadata.name": "gitlab-workspaces"
                  }
                },
                podSelector: {
                  matchLabels: {
                    "app.kubernetes.io/name": "gitlab-workspaces-proxy"
                  }
                }
              }
            ]
          }
        ],
        podSelector: {},
        policyTypes: %w[Ingress Egress]
      }
    }
  end

  def workspace_secrets_inventory(
    workspace_name:,
    workspace_namespace:,
    agent_id:
  )
    {
      kind: "ConfigMap",
      apiVersion: "v1",
      metadata: {
        name: "#{workspace_name}-secrets-inventory",
        namespace: workspace_namespace.to_s,
        labels: {
          "cli-utils.sigs.k8s.io/inventory-id": "#{workspace_name}-secrets-inventory",
          "agent.gitlab.com/id": agent_id.to_s
        }
      }
    }
  end

  def workspace_secret_env_var(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    host_template_annotation:,
    workspace_variables_env_var:
  )
    git_config_count = workspace_variables_env_var.fetch('GIT_CONFIG_COUNT', '')
    git_config_key_0 = workspace_variables_env_var.fetch('GIT_CONFIG_KEY_0', '')
    git_config_value_0 = workspace_variables_env_var.fetch('GIT_CONFIG_VALUE_0', '')
    git_config_key_1 = workspace_variables_env_var.fetch('GIT_CONFIG_KEY_1', '')
    git_config_value_1 = workspace_variables_env_var.fetch('GIT_CONFIG_VALUE_1', '')
    git_config_key_2 = workspace_variables_env_var.fetch('GIT_CONFIG_KEY_2', '')
    git_config_value_2 = workspace_variables_env_var.fetch('GIT_CONFIG_VALUE_2', '')
    gl_git_credential_store_file_path = workspace_variables_env_var.fetch('GL_GIT_CREDENTIAL_STORE_FILE_PATH', '')
    gl_token_file_path = workspace_variables_env_var.fetch('GL_TOKEN_FILE_PATH', '')
    gl_workspace_domain_template = workspace_variables_env_var.fetch('GL_WORKSPACE_DOMAIN_TEMPLATE', '')
    # TODO: figure out why there is flakiness in the order of the environment variables?
    {
      kind: "Secret",
      apiVersion: "v1",
      metadata: {
        name: "#{workspace_name}-env-var",
        namespace: workspace_namespace.to_s,
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-secrets-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        }
      },
      data: {
        GIT_CONFIG_COUNT: Base64.strict_encode64(git_config_count).to_s,
        GIT_CONFIG_KEY_0: Base64.strict_encode64(git_config_key_0).to_s,
        GIT_CONFIG_VALUE_0: Base64.strict_encode64(git_config_value_0).to_s,
        GIT_CONFIG_KEY_1: Base64.strict_encode64(git_config_key_1).to_s,
        GIT_CONFIG_VALUE_1: Base64.strict_encode64(git_config_value_1).to_s,
        GIT_CONFIG_KEY_2: Base64.strict_encode64(git_config_key_2).to_s,
        GIT_CONFIG_VALUE_2: Base64.strict_encode64(git_config_value_2).to_s,
        GL_GIT_CREDENTIAL_STORE_FILE_PATH: Base64.strict_encode64(gl_git_credential_store_file_path).to_s,
        GL_TOKEN_FILE_PATH: Base64.strict_encode64(gl_token_file_path).to_s,
        GL_WORKSPACE_DOMAIN_TEMPLATE: Base64.strict_encode64(gl_workspace_domain_template).to_s
      }
    }
  end

  def workspace_secret_file(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    host_template_annotation:,
    workspace_variables_file:
  )
    gl_git_credential_store = workspace_variables_file.fetch('gl_git_credential_store.sh', '')
    gl_token = workspace_variables_file.fetch('gl_token', '')
    {
      kind: "Secret",
      apiVersion: "v1",
      metadata: {
        name: "#{workspace_name}-file",
        namespace: workspace_namespace.to_s,
        labels: {
          "agent.gitlab.com/id": agent_id.to_s
        },
        annotations: {
          "config.k8s.io/owning-inventory": "#{workspace_name}-secrets-inventory",
          "workspaces.gitlab.com/host-template": host_template_annotation.to_s,
          "workspaces.gitlab.com/id": workspace_id.to_s
        }
      },
      data: {
        gl_token: Base64.strict_encode64(gl_token).to_s,
        "gl_git_credential_store.sh": Base64.strict_encode64(gl_git_credential_store).to_s
      }
    }
  end

  def get_workspace_variables_env_var(workspace_variables:)
    workspace_variables.with_variable_type_env_var.each_with_object({}) do |workspace_variable, hash|
      hash[workspace_variable.key] = workspace_variable.value
    end
  end

  def get_workspace_variables_file(workspace_variables:)
    workspace_variables.with_variable_type_file.each_with_object({}) do |workspace_variable, hash|
      hash[workspace_variable.key] = workspace_variable.value
    end
  end

  # noinspection RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  def get_workspace_host_template_annotation(workspace_name, dns_zone)
    "{{.port}}-#{workspace_name}.#{dns_zone}"
  end

  # noinspection RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  def get_workspace_host_template_env_var(workspace_name, dns_zone)
    "${PORT}-#{workspace_name}.#{dns_zone}"
  end

  def example_devfile
    read_devfile('example.devfile.yaml')
  end

  def example_flattened_devfile
    read_devfile('example.flattened-devfile.yaml')
  end

  def example_processed_devfile
    read_devfile('example.processed-devfile.yaml')
  end

  # TODO: Rename this method and all methods which use it to end in `_yaml`, to clearly distinguish between
  #       a String YAML representation of a devfile, and a devfile which has been converted to a Hash.
  def read_devfile(filename)
    devfile_contents = File.read(Rails.root.join('ee/spec/fixtures/remote_development', filename).to_s)
    devfile_contents.gsub!('http://localhost/', root_url)
    devfile_contents
  end

  def root_url
    # NOTE: Default to http://example.com/ if GitLab::Application is not defined. This allows this helper to be used
    #       from ee/spec/remote_development/fast_spec_helper.rb
    defined?(Gitlab::Application) ? Gitlab::Routing.url_helpers.root_url : 'https://example.com/'
  end
end
