<script>
import { GlButton, GlLink, GlSprintf, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { HELP_PAGE_PATH } from '../constants';
import AllTab from './tabs/all.vue';
import EmptyState from './empty_state.vue';

export default {
  HELP_PAGE_PATH,
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlTabs,
    ConfigurationPageLayout,
    AllTab,
    EmptyState,
  },
  inject: ['newDastScanPath'],
  props: {
    pipelinesCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      activeTabIndex: 0,
    };
  },
  computed: {
    hasData() {
      return this.pipelinesCount > 0;
    },
    tabs() {
      return {
        all: {
          component: AllTab,
          itemsCount: this.pipelinesCount,
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
    <gl-tabs v-model="activeTab">
      <component
        :is="tab.component"
        v-for="(tab, key) in tabs"
        :key="key"
        :items-count="tab.itemsCount"
      />
    </gl-tabs>
  </configuration-page-layout>
  <empty-state v-else />
</template>
