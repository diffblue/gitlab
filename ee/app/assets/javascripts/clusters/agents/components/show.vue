<script>
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AgentShowPage from '~/clusters/agents/components/show.vue';
import AgentVulnerabilityReport from 'ee/security_dashboard/components/agent/agent_vulnerability_report.vue';

export default {
  i18n: {
    securityTabTitle: s__('ClusterAgents|Security'),
  },
  components: {
    AgentShowPage,
    GlTab,
    AgentVulnerabilityReport,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    showSecurityTab() {
      return this.glFeatures.kubernetesClusterVulnerabilities;
    },
  },
};
</script>

<template>
  <agent-show-page>
    <template v-if="showSecurityTab" #ee-security-tab="{ clusterAgentId }">
      <gl-tab :title="$options.i18n.securityTabTitle" query-param-value="security">
        <agent-vulnerability-report :cluster-agent-id="clusterAgentId" />
      </gl-tab>
    </template>
  </agent-show-page>
</template>
