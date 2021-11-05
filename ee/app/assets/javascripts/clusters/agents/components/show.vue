<script>
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AgentShowPage from '~/clusters/agents/components/show.vue';

export default {
  i18n: {
    securityTabTitle: s__('ClusterAgents|Security'),
  },
  components: { AgentShowPage, GlTab },
  mixins: [glFeatureFlagMixin()],
  props: {
    agentName: {
      required: true,
      type: String,
    },
    projectPath: {
      required: true,
      type: String,
    },
  },
  computed: {
    showSecurityTab() {
      return (
        this.glFeatures.kubernetesClusterVulnerabilities && this.glFeatures.clusterVulnerabilities
      );
    },
  },
};
</script>

<template>
  <agent-show-page v-bind="$props">
    <template v-if="showSecurityTab" #ee-security-tab>
      <!-- Placeholder for https://gitlab.com/gitlab-org/gitlab/-/issues/343912-->
      <gl-tab :title="$options.i18n.securityTabTitle"><div></div></gl-tab>
    </template>
  </agent-show-page>
</template>
