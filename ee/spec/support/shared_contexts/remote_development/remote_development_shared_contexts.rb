# frozen_string_literal: true

RSpec.shared_context 'with remote development shared fixtures' do
  # noinspection RubyDeadCode
  # rubocop:disable Metrics/ParameterLists
  def create_workspace_agent_info(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    owning_inventory:,
    resource_version:,
    # NOTE: previous_actual_state is the actual state of the workspace IMMEDIATELY prior to the current state. We don't
    # simulate the situation where there may have been multiple transitions between reconciliation polling intervals.
    previous_actual_state:,
    current_actual_state:,
    # NOTE: workspace_exists is whether the workspace exists in the cluster at the time of the current_actual_state.
    workspace_exists:,
    dns_zone: 'workspaces.localdev.me'
  )
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409787
    #       Default some of the parameters which can be derived from others: e.g. owning_inventory, workspace_namespace

    info = {
      'name' => workspace_name,
      'namespace' => workspace_namespace
    }

    if current_actual_state == RemoteDevelopment::Workspaces::States::TERMINATED
      info['termination_progress'] = RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator::TERMINATED
    end

    if current_actual_state == RemoteDevelopment::Workspaces::States::TERMINATING
      info['termination_progress'] = RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator::TERMINATING
    end

    if [
      RemoteDevelopment::Workspaces::States::TERMINATING,
      RemoteDevelopment::Workspaces::States::TERMINATED,
      RemoteDevelopment::Workspaces::States::UNKNOWN
    ].include?(current_actual_state)
      return info
    end

    spec_replicas = [ # rubocop:disable Style/MultilineTernaryOperator
      RemoteDevelopment::Workspaces::States::STOPPED, RemoteDevelopment::Workspaces::States::STOPPING
    ].include?(current_actual_state) ? 0 : 1
    host_template = get_workspace_host_template(workspace_name, dns_zone)
    root_url = Gitlab::Routing.url_helpers.root_url

    # rubocop:disable Lint/UnreachableCode, Lint/DuplicateBranch
    status =
      case [previous_actual_state, current_actual_state, workspace_exists]
      in [RemoteDevelopment::Workspaces::States::CREATION_REQUESTED, RemoteDevelopment::Workspaces::States::STARTING, _]
        <<~STATUS_YAML
          conditions:
          - lastTransitionTime: "2023-04-10T10:14:14Z"
            lastUpdateTime: "2023-04-10T10:14:14Z"
            message: Created new replica set "#{workspace_name}-hash"
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
            message: ReplicaSet "#{workspace_name}-hash" is progressing.
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
            message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
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
            message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
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
            message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
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
            message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
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
            message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
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
            message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
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
        <<~STATUS_YAML
          conditions:
            - lastTransitionTime: "2023-03-06T14:36:31Z"
              lastUpdateTime: "2023-03-08T11:16:35Z"
              message: ReplicaSet "#{workspace_name}-hash" has successfully progressed.
              reason: NewReplicaSetAvailable
              status: "True"
              type: Progressing
            - lastTransitionTime: "2023-03-08T11:16:55Z"
              lastUpdateTime: "2023-03-08T11:16:55Z"
              message: Deployment does not have minimum availability.
              reason: MinimumReplicasUnavailable
              status: "False"
              type: Available
            replicas: 1
            unavailableReplicas: 1
            updatedReplicas: 1
        STATUS_YAML
      else
        msg = 'Unsupported state transition passed for create_workspace_agent_info fixture creation: ' \
              "actual_state: #{previous_actual_state} -> #{current_actual_state}, " \
              "existing_workspace: #{workspace_exists}"
        raise RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError, msg
      end
    # rubocop:enable Lint/UnreachableCode, Lint/DuplicateBranch

    latest_k8s_deployment_info = <<~RESOURCES_YAML
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        annotations:
          config.k8s.io/owning-inventory: #{owning_inventory}
          workspaces.gitlab.com/host-template: #{host_template}
          workspaces.gitlab.com/id: \'#{workspace_id}\'
        creationTimestamp: null
        labels:
          agent.gitlab.com/id: \'#{agent_id}\'
        name: #{workspace_name}
        namespace: #{workspace_namespace}
        resourceVersion: "#{resource_version}"
      spec:
        replicas: #{spec_replicas}
        selector:
          matchLabels:
            agent.gitlab.com/id: \'#{agent_id}\'
        strategy:
          type: Recreate
        template:
          metadata:
            annotations:
              config.k8s.io/owning-inventory: #{owning_inventory}
              workspaces.gitlab.com/host-template: #{host_template}
              workspaces.gitlab.com/id: \'#{workspace_id}\'
            creationTimestamp: null
            labels:
              agent.gitlab.com/id: \'#{agent_id}\'
            name: #{workspace_name}
            namespace: #{workspace_namespace}
          spec:
            containers:
            - command:
              - "/projects/.gl-editor/start_server.sh"
              env:
              - name: EDITOR_VOLUME_DIR
                value: "/projects/.gl-editor"
              - name: EDITOR_PORT
                value: "60001"
              - name: PROJECTS_ROOT
                value: "/projects"
              - name: PROJECT_SOURCE
                value: "/projects"
              image: quay.io/mloriedo/universal-developer-image:ubi8-dw-demo
              imagePullPolicy: Always
              name: tooling-container
              ports:
              - containerPort: 60001
                name: editor-server
                protocol: TCP
              resources: {}
              volumeMounts:
              - mountPath: "/projects"
                name: gl-workspace-data
              securityContext:
                allowPrivilegeEscalation: false
                privileged: false
                runAsNonRoot: true
                runAsUser: 5001
            initContainers:
            - args:
              - |-
                if [ ! -d '/projects/test-project' ];
                then
                  git clone --branch master #{root_url}test-group/test-project.git /projects/test-project;
                fi
              command: ["/bin/sh", "-c"]
              env:
              - name: PROJECTS_ROOT
                value: "/projects"
              - name: PROJECT_SOURCE
                value: "/projects"
              image: alpine/git:2.36.3
              imagePullPolicy: Always
              name: gl-cloner-injector-gl-cloner-injector-command-1
              resources:
                limits:
                  cpu: 500m
                  memory: 128Mi
                requests:
                  cpu: 30m
                  memory: 32Mi
              volumeMounts:
              - mountPath: "/projects"
                name: gl-workspace-data
              securityContext:
                allowPrivilegeEscalation: false
                privileged: false
                runAsNonRoot: true
                runAsUser: 5001
            - env:
              - name: EDITOR_VOLUME_DIR
                value: "/projects/.gl-editor"
              - name: EDITOR_PORT
                value: "60001"
              - name: PROJECTS_ROOT
                value: "/projects"
              - name: PROJECT_SOURCE
                value: "/projects"
              image: registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector:1
              imagePullPolicy: Always
              name: gl-editor-injector-gl-editor-injector-command-2
              resources:
                limits:
                  cpu: 500m
                  memory: 128Mi
                requests:
                  cpu: 30m
                  memory: 32Mi
              volumeMounts:
              - mountPath: "/projects"
                name: gl-workspace-data
              securityContext:
                allowPrivilegeEscalation: false
                privileged: false
                runAsNonRoot: true
                runAsUser: 5001
            volumes:
            - name: gl-workspace-data
              persistentVolumeClaim:
                claimName: #{workspace_name}-gl-workspace-data
            securityContext:
              runAsNonRoot: true
              runAsUser: 5001
      status:
      #{status.indent(2)}
    RESOURCES_YAML

    info['latest_k8s_deployment_info'] = YAML.safe_load(latest_k8s_deployment_info)
    info
  end
  # rubocop:enable Metrics/ParameterLists

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

  def create_config_to_apply(
    workspace_id:,
    workspace_name:,
    workspace_namespace:,
    agent_id:,
    owning_inventory:,
    started:,
    include_inventory: true,
    dns_zone: 'workspaces.localdev.me'
  )
    spec_replicas = started == true ? "1" : "0"
    host_template = get_workspace_host_template(workspace_name, dns_zone)
    root_url = Gitlab::Routing.url_helpers.root_url
    inventory_config = <<~RESOURCES_YAML
      ---
      kind: ConfigMap
      apiVersion: v1
      metadata:
        name: #{owning_inventory}
        namespace: #{workspace_namespace}
        labels:
          cli-utils.sigs.k8s.io/inventory-id: #{owning_inventory}
          agent.gitlab.com/id: \'#{agent_id}\'
    RESOURCES_YAML

    resources = <<~RESOURCES_YAML
      ---
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        annotations:
          config.k8s.io/owning-inventory: #{owning_inventory}
          workspaces.gitlab.com/host-template: #{host_template}
          workspaces.gitlab.com/id: \'#{workspace_id}\'
        creationTimestamp: null
        labels:
          agent.gitlab.com/id: \'#{agent_id}\'
        name: #{workspace_name}
        namespace: #{workspace_namespace}
      spec:
        replicas: #{spec_replicas}
        selector:
          matchLabels:
            agent.gitlab.com/id: \'#{agent_id}\'
        strategy:
          type: Recreate
        template:
          metadata:
            annotations:
              config.k8s.io/owning-inventory: #{owning_inventory}
              workspaces.gitlab.com/host-template: #{host_template}
              workspaces.gitlab.com/id: \'#{workspace_id}\'
            creationTimestamp: null
            labels:
              agent.gitlab.com/id: \'#{agent_id}\'
            name: #{workspace_name}
            namespace: #{workspace_namespace}
          spec:
            containers:
            - command:
              - "/projects/.gl-editor/start_server.sh"
              env:
              - name: EDITOR_VOLUME_DIR
                value: "/projects/.gl-editor"
              - name: EDITOR_PORT
                value: "60001"
              - name: PROJECTS_ROOT
                value: "/projects"
              - name: PROJECT_SOURCE
                value: "/projects"
              image: quay.io/mloriedo/universal-developer-image:ubi8-dw-demo
              imagePullPolicy: Always
              name: tooling-container
              ports:
              - containerPort: 60001
                name: editor-server
                protocol: TCP
              resources: {}
              volumeMounts:
              - mountPath: "/projects"
                name: gl-workspace-data
              securityContext:
                allowPrivilegeEscalation: false
                privileged: false
                runAsNonRoot: true
                runAsUser: 5001
            initContainers:
            - args:
              - |-
                if [ ! -d '/projects/test-project' ];
                then
                  git clone --branch master #{root_url}test-group/test-project.git /projects/test-project;
                fi
              command: ["/bin/sh", "-c"]
              env:
              - name: PROJECTS_ROOT
                value: "/projects"
              - name: PROJECT_SOURCE
                value: "/projects"
              image: alpine/git:2.36.3
              imagePullPolicy: Always
              name: gl-cloner-injector-gl-cloner-injector-command-1
              resources:
                limits:
                  cpu: 500m
                  memory: 128Mi
                requests:
                  cpu: 30m
                  memory: 32Mi
              volumeMounts:
              - mountPath: "/projects"
                name: gl-workspace-data
              securityContext:
                allowPrivilegeEscalation: false
                privileged: false
                runAsNonRoot: true
                runAsUser: 5001
            - env:
              - name: EDITOR_VOLUME_DIR
                value: "/projects/.gl-editor"
              - name: EDITOR_PORT
                value: "60001"
              - name: PROJECTS_ROOT
                value: "/projects"
              - name: PROJECT_SOURCE
                value: "/projects"
              image: registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector:1
              imagePullPolicy: Always
              name: gl-editor-injector-gl-editor-injector-command-2
              resources:
                limits:
                  cpu: 500m
                  memory: 128Mi
                requests:
                  cpu: 30m
                  memory: 32Mi
              volumeMounts:
              - mountPath: "/projects"
                name: gl-workspace-data
              securityContext:
                allowPrivilegeEscalation: false
                privileged: false
                runAsNonRoot: true
                runAsUser: 5001
            volumes:
            - name: gl-workspace-data
              persistentVolumeClaim:
                claimName: #{workspace_name}-gl-workspace-data
            securityContext:
              runAsNonRoot: true
              runAsUser: 5001
      status: {}
      ---
      apiVersion: v1
      kind: Service
      metadata:
        annotations:
          config.k8s.io/owning-inventory: #{owning_inventory}
          workspaces.gitlab.com/host-template: #{host_template}
          workspaces.gitlab.com/id: \'#{workspace_id}\'
        creationTimestamp: null
        labels:
          agent.gitlab.com/id: \'#{agent_id}\'
        name: #{workspace_name}
        namespace: #{workspace_namespace}
      spec:
        ports:
        - name: editor-server
          port: 60001
          targetPort: 60001
        selector:
          agent.gitlab.com/id: \'#{agent_id}\'
      status:
        loadBalancer: {}
      ---
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        annotations:
          config.k8s.io/owning-inventory: #{owning_inventory}
          workspaces.gitlab.com/host-template: #{host_template}
          workspaces.gitlab.com/id: \'#{workspace_id}\'
        creationTimestamp:
        labels:
          agent.gitlab.com/id: \'#{agent_id}\'
        name: #{workspace_name}-gl-workspace-data
        namespace: #{workspace_namespace}
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 15Gi
      status: {}
    RESOURCES_YAML

    unless include_inventory
      return YAML.load_stream(resources).map do |resource|
        YAML.dump(resource)
      end.join
    end

    YAML.load_stream(inventory_config + resources).map do |resource|
      YAML.dump(resource)
    end.join
  end

  def get_workspace_host_template(workspace_name, dns_zone)
    "\"{{.port}}-#{workspace_name}.#{dns_zone}\""
  end

  def example_devfile
    read_devfile('example.devfile.yaml')
  end

  def example_processed_devfile
    devfile_contents = read_devfile('example.processed-devfile.yaml')
    devfile_contents.gsub!('http://localhost/', Gitlab::Routing.url_helpers.root_url)
    devfile_contents
  end

  def read_devfile(filename)
    # noinspection RubyMismatchedArgumentType
    File.read(Rails.root.join('ee/spec/fixtures/remote_development', filename))
  end
end
