<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { AUDIT_EVENTS_TAB_TITLES } from '../constants';
import AuditEventsLog from './audit_events_log.vue';
import AuditEventsStream from './audit_events_stream.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    AuditEventsLog,
    AuditEventsStream,
  },
  inject: ['isProject', 'showStreams'],
  computed: {
    showTabs() {
      return !this.isProject && this.showStreams;
    },
  },
  i18n: AUDIT_EVENTS_TAB_TITLES,
};
</script>

<template>
  <gl-tabs v-if="showTabs" content-class="gl-pt-5">
    <gl-tab :title="$options.i18n.LOG">
      <audit-events-log />
    </gl-tab>
    <gl-tab :title="$options.i18n.STREAM" lazy>
      <audit-events-stream />
    </gl-tab>
  </gl-tabs>
  <audit-events-log v-else />
</template>
