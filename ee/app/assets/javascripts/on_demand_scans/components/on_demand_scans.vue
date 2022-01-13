<script>
import { GlButton, GlLink, GlSprintf, GlScrollableTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import {
  getQueryHeaders,
  toggleQueryPollingByVisibility,
} from '~/pipelines/components/graph/utils';
import onDemandScanCounts from '../graphql/on_demand_scan_counts.query.graphql';
import {
  HELP_PAGE_PATH,
  PIPELINE_TABS_KEYS,
  PIPELINES_COUNT_POLL_INTERVAL,
  PIPELINES_SCOPE_RUNNING,
  PIPELINES_SCOPE_FINISHED,
} from '../constants';
import AllTab from './tabs/all.vue';
import RunningTab from './tabs/running.vue';
import FinishedTab from './tabs/finished.vue';
import ScheduledTab from './tabs/scheduled.vue';
import SavedTab from './tabs/saved.vue';
import EmptyState from './empty_state.vue';

export default {
  HELP_PAGE_PATH,
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlScrollableTabs,
    ConfigurationPageLayout,
    AllTab,
    RunningTab,
    FinishedTab,
    ScheduledTab,
    EmptyState,
  },
  inject: ['newDastScanPath', 'projectPath', 'projectOnDemandScanCountsEtag'],
  apollo: {
    liveOnDemandScanCounts: {
      query: onDemandScanCounts,
      variables() {
        return {
          fullPath: this.projectPath,
          runningScope: PIPELINES_SCOPE_RUNNING,
          finishedScope: PIPELINES_SCOPE_FINISHED,
        };
      },
      context() {
        return getQueryHeaders(this.projectOnDemandScanCountsEtag);
      },
      update(data) {
        return Object.fromEntries(
          PIPELINE_TABS_KEYS.map((key) => {
            const { count } = data[key].pipelines;
            return [key, count];
          }),
        );
      },
      pollInterval: PIPELINES_COUNT_POLL_INTERVAL,
    },
  },
  props: {
    initialOnDemandScanCounts: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      activeTabIndex: 0,
    };
  },
  computed: {
    onDemandScanCounts() {
      return this.liveOnDemandScanCounts ?? this.initialOnDemandScanCounts;
    },
    hasData() {
      // Scheduled and saved scans aren't included in the total count because they are
      // dastProfiles, not pipelines.
      // When https://gitlab.com/gitlab-org/gitlab/-/issues/342950 is addressed, we won't need to
      // include scheduled scans in the calculation. We'll still need to include saved scans as
      // those will likely neverr be considered pipelines.
      return (
        this.onDemandScanCounts.all +
          this.onDemandScanCounts.scheduled +
          this.onDemandScanCounts.saved >
        0
      );
    },
    tabs() {
      return {
        all: {
          component: AllTab,
          itemsCount: this.onDemandScanCounts.all,
        },
        running: {
          component: RunningTab,
          itemsCount: this.onDemandScanCounts.running,
        },
        finished: {
          component: FinishedTab,
          itemsCount: this.onDemandScanCounts.finished,
        },
        scheduled: {
          component: ScheduledTab,
          itemsCount: this.onDemandScanCounts.scheduled,
        },
        saved: {
          component: SavedTab,
          itemsCount: this.onDemandScanCounts.saved,
        },
      };
    },
    activeTab: {
      set(newTabIndex) {
        const newTabId = Object.keys(this.tabs)[newTabIndex];
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
    const tabIndex = Object.keys(this.tabs).findIndex((tab) => tab === this.$route.params.tabId);
    if (tabIndex !== -1) {
      this.activeTabIndex = tabIndex;
    }
  },
  mounted() {
    toggleQueryPollingByVisibility(
      this.$apollo.queries.liveOnDemandScanCounts,
      PIPELINES_COUNT_POLL_INTERVAL,
    );
  },
  i18n: {
    title: s__('OnDemandScans|On-demand scans'),
    newScanButtonLabel: s__('OnDemandScans|New DAST scan'),
    description: s__(
      'OnDemandScans|On-demand scans run outside of DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}.',
    ),
  },
};
</script>

<template>
  <configuration-page-layout v-if="hasData" no-border>
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
          <gl-link :href="$options.HELP_PAGE_PATH" data-testid="help-page-link">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
    <gl-scrollable-tabs v-model="activeTab" data-testid="on-demand-scans-tabs">
      <component
        :is="tab.component"
        v-for="(tab, key, index) in tabs"
        :key="key"
        :items-count="tab.itemsCount"
        :is-active="activeTab === index"
      />
    </gl-scrollable-tabs>
  </configuration-page-layout>
  <empty-state v-else />
</template>
