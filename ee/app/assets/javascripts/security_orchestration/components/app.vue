<script>
import { GlIcon, GlLink, GlPopover, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import Alerts from './alerts/alerts.vue';

export default {
  name: 'ThreatMonitoring',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlTabs,
    GlTab,
    Alerts,
  },
  inject: ['documentationPath'],
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
          <gl-icon name="question-o" />
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
    </gl-tabs>
  </section>
</template>
