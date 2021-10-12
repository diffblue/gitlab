<script>
import { GlButton, GlLink, GlSprintf, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import AllTab from './tabs/all.vue';
import RunningTab from './tabs/running.vue';
import FinishedTab from './tabs/finished.vue';
import ScheduledTab from './tabs/scheduled.vue';
import EmptyState from './empty_state.vue';

const TABS = {
  all: {
    component: AllTab,
  },
  running: {
    component: RunningTab,
  },
  finished: {
    component: FinishedTab,
  },
  scheduled: {
    component: ScheduledTab,
  },
};

export default {
  TABS,
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlTabs,
    ConfigurationPageLayout,
    AllTab,
    RunningTab,
    FinishedTab,
    ScheduledTab,
    EmptyState,
  },
  inject: ['newDastScanPath', 'helpPagePath'],
  data() {
    return {
      activeTabIndex: 0,
      hasData: false,
    };
  },
  computed: {
    activeTab: {
      set(newTabIndex) {
        const newTabId = Object.keys(TABS)[newTabIndex];
        if (this.$route.params.tabId !== newTabId) {
          this.$router.push(`/${newTabId}`);
        }
        this.activeTabIndex = newTabIndex;
      },
      get() {
        return this.activeTabIndex;
      },
    },
  },
  created() {
    const tabIndex = Object.keys(TABS).findIndex((tab) => tab === this.$route.params.tabId);
    if (tabIndex !== -1) {
      this.activeTabIndex = tabIndex;
    }
  },
  i18n: {
    title: s__('OnDemandScans|On-demand scans'),
    newScanButtonLabel: s__('OnDemandScans|New DAST scan'),
    description: s__(
      'OnDemandScans|On-demand scans run outside of DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Lean more%{learnMoreLinkEnd}.',
    ),
  },
};
</script>

<template>
  <configuration-page-layout v-if="hasData">
    <template #heading>
      {{ $options.i18n.title }}
    </template>
    <template #actions>
      <gl-button variant="confirm" :href="newDastScanPath" data-testid="new-scan-link">
        {{ $options.i18n.newScanButtonLabel }}
      </gl-button>
    </template>
    <template #description>
      <gl-sprintf :message="$options.i18n.description">
        <template #learnMoreLink="{ content }">
          <gl-link :href="helpPagePath" data-testid="help-page-link">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <gl-tabs v-model="activeTab">
      <component
        :is="tab.component"
        v-for="(tab, key) in $options.TABS"
        :key="key"
        :item-count="0"
      />
    </gl-tabs>
  </configuration-page-layout>
  <empty-state v-else />
</template>
