<script>
import { GlAlert, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import getAgentCount from '../../graphql/queries/get_agent_count.query.graphql';

export default {
  i18n: {
    ACTION: s__(
      'NetworkPolicies|%{labelStart}And%{labelEnd} %{spanStart}send an Alert to GitLab.%{spanEnd}',
    ),
    AGENT_REQUIRED: s__(
      'NetworkPolicies|Please %{installLinkStart}install%{installLinkEnd} and %{configureLinkStart}configure a Kubernetes Agent for this project%{configureLinkEnd} to enable alerts.',
    ),
    BUTTON_LABEL: s__('NetworkPolicies|Add alert'),
    HIGH_VOLUME_WARNING: s__(
      `NetworkPolicies|Alerts are intended to be selectively used for a limited number of events that are potentially concerning and warrant a manual review. Alerts should not be used as a substitute for a SIEM or a logging tool. High volume alerts are likely to be dropped so as to preserve the stability of GitLab's integration with Kubernetes.`,
    ),
    REMOVE: __('Remove'),
  },
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlSprintf,
  },
  inject: {
    configureAgentHelpPath: { type: String, default: '' },
    createAgentHelpPath: { type: String, default: '' },
    projectPath: { type: String, default: '' },
  },
  props: {
    policyAlert: { type: Boolean, required: true },
  },
  apollo: {
    agentCount: {
      query: getAgentCount,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data?.project?.clusterAgents?.count || 0;
      },
    },
  },
  data() {
    return {
      agentCount: 0,
    };
  },
  computed: {
    agentLoading() {
      return this.$apollo.queries.agentCount.loading;
    },
    isAgentInstalled() {
      return Boolean(this.agentCount) && !this.agentLoading;
    },
    spacingClass() {
      return { 'gl-mt-5': !this.policyAlert && this.isAgentInstalled };
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="!isAgentInstalled"
      variant="danger"
      :dismissible="false"
      class="gl-mt-5"
      data-testid="policy-alert-no-agent"
    >
      <gl-sprintf :message="$options.i18n.AGENT_REQUIRED">
        <template #installLink="{ content }">
          <gl-link :href="createAgentHelpPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
        <template #configureLink="{ content }">
          <gl-link :href="configureAgentHelpPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-else-if="policyAlert"
      variant="warning"
      :dismissible="false"
      class="gl-mt-5"
      data-testid="policy-alert-high-volume"
    >
      {{ $options.i18n.HIGH_VOLUME_WARNING }}
    </gl-alert>
    <div
      class="gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base gl-p-5"
      :class="spacingClass"
    >
      <gl-button
        v-if="!policyAlert"
        variant="link"
        category="primary"
        data-testid="add-alert"
        icon="plus"
        :disabled="!isAgentInstalled"
        @click="$emit('update-alert', !policyAlert)"
      >
        {{ $options.i18n.BUTTON_LABEL }}
      </gl-button>
      <div
        v-else
        class="gl-w-full gl-display-flex gl-justify-content-space-between gl-align-items-center"
      >
        <span>
          <gl-sprintf :message="$options.i18n.ACTION" data-testid="policy-alert-message">
            <template #label="{ content }">
              <label for="actionType" class="text-uppercase gl-font-lg gl-mr-4 gl-mb-0">
                {{ content }}
              </label>
            </template>
            <template #span="{ content }">
              <span>{{ content }}</span>
            </template>
          </gl-sprintf>
        </span>
        <gl-button
          data-testid="remove-alert"
          icon="remove"
          category="tertiary"
          :aria-label="$options.i18n.REMOVE"
          @click="$emit('update-alert', !policyAlert)"
        />
      </div>
    </div>
  </div>
</template>
