# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class ActualStateCalculator
        include States

        TERMINATION_PROGRESS_TERMINATING = 'Terminating'
        TERMINATION_PROGRESS_TERMINATED = 'Terminated'

        CONDITION_TYPE_PROGRESSING = 'Progressing'
        CONDITION_TYPE_AVAILABLE = 'Available'
        PROGRESSING_CONDITION_REASON_NEW_REPLICA_SET_CREATED = 'NewReplicaSetCreated'
        PROGRESSING_CONDITION_REASON_FOUND_NEW_REPLICA_SET = 'FoundNewReplicaSet'
        PROGRESSING_CONDITION_REASON_REPLICA_SET_UPDATED = 'ReplicaSetUpdated'
        PROGRESSING_CONDITION_REASON_NEW_REPLICA_SET_AVAILABLE = 'NewReplicaSetAvailable'
        PROGRESSING_CONDITION_REASON_PROGRESS_DEADLINE_EXCEEDED = 'ProgressDeadlineExceeded'
        AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_UNAVAILABLE = 'MinimumReplicasUnavailable'
        AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_AVAILABLE = 'MinimumReplicasAvailable'

        DEPLOYMENT_PROGRESSING_STATUS_PROGRESSING = [
          PROGRESSING_CONDITION_REASON_NEW_REPLICA_SET_CREATED,
          PROGRESSING_CONDITION_REASON_FOUND_NEW_REPLICA_SET,
          PROGRESSING_CONDITION_REASON_REPLICA_SET_UPDATED
        ].freeze

        DEPLOYMENT_PROGRESSING_STATUS_COMPLETE = [
          PROGRESSING_CONDITION_REASON_NEW_REPLICA_SET_AVAILABLE
        ].freeze

        DEPLOYMENT_PROGRESSING_STATUS_FAILED = [
          PROGRESSING_CONDITION_REASON_PROGRESS_DEADLINE_EXCEEDED
        ].freeze

        # rubocop: disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def calculate_actual_state(latest_k8s_deployment_info:, termination_progress: nil)
          return TERMINATING if termination_progress == TERMINATION_PROGRESS_TERMINATING
          return TERMINATED if termination_progress == TERMINATION_PROGRESS_TERMINATED

          # if latest_k8s_deployment_info is missing, but workspace isn't Terminated or Terminating, this is an Unknown
          # state and should likely be accompanied by a value in the Error field, as this should be detectable by
          # agentk. At that point, this may not be necessary, and we can detect the error state earlier and return in a
          # guard clause before this point.
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/396882#note_1377670883
          #       Error field is not yet implemented, double check the above comment once it is implemented
          return UNKNOWN unless latest_k8s_deployment_info

          spec = latest_k8s_deployment_info['spec']
          status = latest_k8s_deployment_info['status']
          conditions = status&.[]('conditions')
          return UNKNOWN unless spec && status && conditions

          progressing_condition = conditions.detect do |condition|
            condition['type'] == CONDITION_TYPE_PROGRESSING
          end
          return UNKNOWN if progressing_condition.nil?

          progressing_reason = progressing_condition['reason']
          spec_replicas = spec['replicas']
          return UNKNOWN if progressing_reason.nil? || spec_replicas.nil?

          # https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#deployment-status

          # If the deployment has been marked failed, we know that the workspace has failed
          # A deployment is failed if
          # - Insufficient quota
          # - Readiness probe failures
          # - Image pull errors
          # - Insufficient permissions
          # - Limit ranges
          # - Application runtime misconfiguration
          return FAILED if DEPLOYMENT_PROGRESSING_STATUS_FAILED.include?(progressing_reason)

          # If the deployment is still in progress, the workspace can only be either starting or stopping
          # A deployment is in progress if
          # - The Deployment creates a new ReplicaSet.
          # - The Deployment is scaling up its newest ReplicaSet.
          # - The Deployment is scaling down its older ReplicaSet(s).
          # - New Pods become ready or available (ready for at least MinReadySeconds).
          if DEPLOYMENT_PROGRESSING_STATUS_PROGRESSING.include?(progressing_reason)
            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409777
            #       This does not appear to be the normal STOPPING or STARTING scenario, because the progressing_reason
            #       always remains 'NewReplicaSetAvailable' even when transitioning between Running and Stopped.
            return STOPPING if spec_replicas == 0
            return STARTING if spec_replicas == 1
          end

          # https://github.com/kubernetes/kubernetes/blob/3615291/pkg/controller/deployment/sync.go#L513-L516
          status_available_replicas = status.fetch('availableReplicas', 0)
          status_unavailable_replicas = status.fetch('unavailableReplicas', 0)

          available_condition = conditions.detect do |condition|
            condition['type'] == CONDITION_TYPE_AVAILABLE
          end
          return UNKNOWN if available_condition.nil?

          available_reason = available_condition['reason']
          return UNKNOWN if available_reason.nil?

          # If a deployment has been marked complete, the workspace state needs to be further calculated
          # A deployment is complete if
          # - All of the replicas associated with the Deployment have been updated to the latest version
          # you've specified, meaning any updates you've requested have been completed.
          # - All of the replicas associated with the Deployment are available.
          # - No old replicas for the Deployment are running.
          if DEPLOYMENT_PROGRESSING_STATUS_COMPLETE.include?(progressing_reason)
            # rubocop:disable Layout/MultilineOperationIndentation - Currently can't override default RubyMine formatting

            # If a deployment is complete and the desired and available replicas are 0, the workspace is stopped
            if available_reason == AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_AVAILABLE &&
              spec_replicas == 0 && status_available_replicas == 0
              return STOPPED
            end

            # If a deployment is complete and the Available condition has reason MinimumReplicasAvailable
            # and the desired and available replicas are equal
            # and there are no unavailable replicas
            # then the workspace is running
            if available_reason == AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_AVAILABLE &&
              spec_replicas == status_available_replicas &&
              status_unavailable_replicas == 0
              return RUNNING
            end

            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409777
            #       This appears to be the normal STOPPING scenario, because the progressing_reason always remains
            #       'NewReplicaSetAvailable' when transitioning between Running and Stopped. Confirm if different
            #       handling of STOPPING status above is also necessary.
            #       In normal usage (at least in local dev), this transition always happens so fast that this
            #       state is never sent in a reconciliation request, even with a 1-second polling interval.
            #       It always stopped immediately in under a second, and thus the next poll after a Stopped
            #       request always ends up with spec_replicas == 0 && status_available_replicas == 0 and
            #       matches the STOPPED state above.
            if available_reason == AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_AVAILABLE &&
              spec_replicas == 0 && status_available_replicas == 1
              return STOPPING
            end

            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409777
            #       This appears to be the normal STARTING scenario, because the progressing_reason always remains
            #       'NewReplicaSetAvailable' and available_reason is either 'MinimumReplicasAvailable' or
            #      'MinimumReplicasUnavailable' when transitioning between Stopped and Running. Confirm if different
            #       handling of STARTING status above is also necessary.
            if [
              AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_AVAILABLE,
              AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_UNAVAILABLE
            ].include?(available_reason) &&
              spec_replicas == 1 && status_available_replicas == 0
              return STARTING
            end

            # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409777
            #       This is unreachable by any of the currently implemented fixture scenarios, because it matches the
            #       normal behavior when transioning between Stopped and Running. We need to determine what
            #       a failure scenario actually looks like and how it differs, if at all, from a normal STARTING
            #       scenario. Logic is commented out to avoid undercoverage failure. See related TODOs above.
            # If a deployment is complete and the Available condition has reason MinimumReplicasUnavailable
            # and the desired and available replicas are not equal
            # and there are unavailable replicas
            # then the workspace is failed
            # Example: Deployment is completed and the ReplicaSet is available and up-to-date.
            # But the Pods of the ReplicaSet are not available as they are in CrashLoopBackOff
            # if available_reason == AVAILABLE_CONDITION_REASON_MINIMUM_REPLICAS_UNAVAILABLE &&
            #   spec_replicas != status_available_replicas &&
            #   status_unavailable_replicas != 0
            #   return FAILED
            # end

            # rubocop:enable Layout/MultilineOperationIndentation - Currently can't override default RubyMine formatting
          end

          UNKNOWN
        end

        # rubocop: enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      end
    end
  end
end
