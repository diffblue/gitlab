<script>
import { GlIcon, GlLink, GlPopover, GlTabs, GlTab } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Alerts from './alerts/alerts.vue';
import NoEnvironmentEmptyState from './no_environment_empty_state.vue';
import PolicyList from './policy_list.vue';
import ThreatMonitoringFilters from './threat_monitoring_filters.vue';
import ThreatMonitoringSection from './threat_monitoring_section.vue';

export default {
  name: 'ThreatMonitoring',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlTabs,
    GlTab,
    Alerts,
    ThreatMonitoringFilters,
    ThreatMonitoringSection,
    PolicyList,
    NoEnvironmentEmptyState,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['documentationPath'],
  props: {
    defaultEnvironmentId: {
      type: Number,
      required: true,
    },
    networkPolicyNoDataSvgPath: {
      type: String,
      required: true,
    },
    newPolicyPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      // We require the project to have at least one available environment.
      // An invalid default environment id means there there are no available
      // environments, therefore infrastructure cannot be set up. A valid default
      // environment id only means that infrastructure *might* be set up.
      isSetUpMaybe: this.isValidEnvironmentId(this.defaultEnvironmentId),
    };
  },
  computed: {
    shouldShowPolicies() {
      return !this.glFeatures.securityOrchestrationPoliciesConfiguration;
    },
  },
  created() {
    if (this.isSetUpMaybe) {
      this.setCurrentEnvironmentId(this.defaultEnvironmentId);
      this.fetchEnvironments();
    }
  },
  methods: {
    ...mapActions('threatMonitoring', ['fetchEnvironments', 'setCurrentEnvironmentId']),
    isValidEnvironmentId(id) {
      return Number.isInteger(id) && id >= 0;
    },
  },
  networkPolicyChartEmptyStateDescription: s__(
    `ThreatMonitoring|Container Network Policies are not installed or have been disabled. To view
     this data, ensure your Network Policies are installed and enabled for your cluster.`,
  ),
  helpPopoverText: s__('ThreatMonitoring|View documentation'),
};
</script>

<template>
  <section data-qa-selector="threat_monitoring_container">
    <header class="my-3">
      <h2 class="h3 mb-1 gl-display-flex gl-align-items-center">
        {{ s__('ThreatMonitoring|Threat Monitoring') }}
        <gl-link
          ref="helpLink"
          class="gl-ml-3"
          target="_blank"
          :href="documentationPath"
          :aria-label="s__('ThreatMonitoring|Threat Monitoring help page link')"
        >
          <gl-icon name="question" />
        </gl-link>
        <gl-popover :target="() => $refs.helpLink">
          {{ $options.helpPopoverText }}
        </gl-popover>
      </h2>
    </header>

    <gl-tabs content-class="gl-pt-0">
      <gl-tab
        :title="s__('ThreatMonitoring|Alerts')"
        data-testid="threat-monitoring-alerts-tab"
        data-qa-selector="alerts_tab"
      >
        <alerts />
      </gl-tab>
      <gl-tab
        v-if="shouldShowPolicies"
        ref="policyTab"
        :title="s__('ThreatMonitoring|Policies')"
        data-qa-selector="policies_tab"
      >
        <no-environment-empty-state v-if="!isSetUpMaybe" />
        <policy-list
          v-else
          :documentation-path="documentationPath"
          :new-policy-path="newPolicyPath"
        />
      </gl-tab>
      <gl-tab
        :title="s__('ThreatMonitoring|Statistics')"
        data-testid="threat-monitoring-statistics-tab"
      >
        <no-environment-empty-state v-if="!isSetUpMaybe" />
        <template v-else>
          <threat-monitoring-filters />

          <threat-monitoring-section
            ref="policySection"
            store-namespace="threatMonitoringNetworkPolicy"
            :title="s__('ThreatMonitoring|Container Network Policy')"
            :subtitle="s__('ThreatMonitoring|Packet Activity')"
            :anomalous-title="s__('ThreatMonitoring|Dropped Packets')"
            :nominal-title="s__('ThreatMonitoring|Total Packets')"
            :y-legend="s__('ThreatMonitoring|Operations Per Second')"
            :chart-empty-state-title="
              s__('ThreatMonitoring|Container NetworkPolicies not detected')
            "
            :chart-empty-state-text="$options.networkPolicyChartEmptyStateDescription"
            :chart-empty-state-svg-path="networkPolicyNoDataSvgPath"
            :documentation-path="documentationPath"
            documentation-anchor="container-network-policy"
          />
        </template>
      </gl-tab>
    </gl-tabs>
  </section>
</template>
