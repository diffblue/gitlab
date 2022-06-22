<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import Tracking from '~/tracking';
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
  mixins: [Tracking.mixin()],
  inject: ['isProject', 'showStreams'],
  computed: {
    showTabs() {
      return !this.isProject && this.showStreams;
    },
  },
  methods: {
    onTabClick() {
      this.track('click_tab', { label: 'audit_events_streams_tab' });
    },
  },
  i18n: AUDIT_EVENTS_TAB_TITLES,
};
</script>

<template>
  <gl-tabs v-if="showTabs" content-class="gl-pt-5" :sync-active-tab-with-query-params="true">
    <gl-tab :title="$options.i18n.LOG" query-param-value="log">
      <audit-events-log />
    </gl-tab>
    <gl-tab
      :title="$options.i18n.STREAM"
      query-param-value="streams"
      lazy
      data-testid="streams-tab"
      @click="onTabClick"
    >
      <audit-events-stream />
    </gl-tab>
  </gl-tabs>
  <audit-events-log v-else />
</template>
