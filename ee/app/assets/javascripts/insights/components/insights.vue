<script>
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlEmptyState,
  GlLoadingIcon,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  EMPTY_STATE_TITLE,
  EMPTY_STATE_DESCRIPTION,
  EMPTY_STATE_SVG_PATH,
  INSIGHTS_CONFIGURATION_TEXT,
  INSIGHTS_PAGE_FILTERED_OUT,
  INSIGHTS_REPORT_DROPDOWN_EMPTY_TEXT,
} from '../constants';
import InsightsPage from './insights_page.vue';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    InsightsPage,
    GlEmptyState,
    GlDropdown,
    GlDropdownItem,
    GlLink,
    GlSprintf,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    queryEndpoint: {
      type: String,
      required: true,
    },
    notice: {
      type: String,
      default: '',
      required: false,
    },
  },
  computed: {
    ...mapState('insights', [
      'configData',
      'configLoading',
      'activeTab',
      'activePage',
      'chartData',
    ]),
    emptyState() {
      return {
        title: EMPTY_STATE_TITLE,
        description: EMPTY_STATE_DESCRIPTION,
        svgPath: EMPTY_STATE_SVG_PATH,
      };
    },
    hasAllChartsLoaded() {
      const requestedChartKeys = this.activePage?.charts?.map((chart) => chart.title) || [];
      return requestedChartKeys.every((key) => this.chartData[key]?.loaded);
    },
    hasChartsError() {
      return Object.values(this.chartData).some((data) => data.error);
    },
    pageLoading() {
      return !this.hasChartsError && !this.hasAllChartsLoaded;
    },
    pages() {
      const { configData, activeTab } = this;

      if (!configData) {
        return [];
      }

      if (!activeTab) {
        if (this.validSpecifiedTab()) {
          this.setActiveTab(this.specifiedTab);
        } else {
          const defaultTab = Object.keys(configData)[0];

          this.setActiveTab(defaultTab);
          this.$router.replace(defaultTab);
        }
      }

      return Object.keys(configData).map((key) => ({
        name: configData[key].title,
        scope: key,
        isActive: this.activeTab === key,
      }));
    },
    allItemsAreFilteredOut() {
      return this.configPresent && Object.keys(this.configData).length === 0;
    },
    configPresent() {
      return !this.configLoading && this.configData != null;
    },
    specifiedTab() {
      return this.$route.params.tabId;
    },
    pageDropdownTitle() {
      return (
        (this.activeTab && this.configData[this.activeTab]?.title) ||
        INSIGHTS_REPORT_DROPDOWN_EMPTY_TEXT
      );
    },
  },
  mounted() {
    this.fetchConfigData(this.endpoint);
  },
  methods: {
    ...mapActions('insights', ['fetchConfigData', 'setActiveTab']),
    onChangePage(page) {
      if (this.validTab(page) && this.activeTab !== page) {
        this.$router.push(page);
      }
    },
    validSpecifiedTab() {
      return this.specifiedTab && this.validTab(this.specifiedTab);
    },
    validTab(tab) {
      return Object.prototype.hasOwnProperty.call(this.configData, tab);
    },
  },
  i18n: {
    insightsConfigurationText: INSIGHTS_CONFIGURATION_TEXT,
    insightsPageFilteredOut: INSIGHTS_PAGE_FILTERED_OUT,
  },
  insightsDocumentationLink: helpPagePath('user/group/insights/index.md', {
    anchor: 'configure-your-insights',
  }),
};
</script>
<template>
  <div class="insights-container gl-mt-3">
    <div class="gl-mb-5">
      <h3>{{ __('Insights') }}</h3>
    </div>
    <p>
      <gl-sprintf :message="$options.i18n.insightsConfigurationText">
        <template #link="{ content }">
          <gl-link :href="$options.insightsDocumentationLink">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <div v-if="configLoading" class="insights-config-loading gl-text-center">
      <gl-loading-icon :inline="true" size="lg" />
    </div>
    <div v-else-if="allItemsAreFilteredOut" class="insights-wrapper">
      <gl-alert>{{ $options.i18n.insightsPageFilteredOut }}</gl-alert>
    </div>
    <div v-else-if="configPresent" class="insights-wrapper">
      <gl-dropdown
        class="js-insights-dropdown"
        data-qa-selector="insights_dashboard_dropdown"
        toggle-class="dropdown-menu-toggle gl-field-error-outline"
        :text="pageDropdownTitle"
        :disabled="pageLoading"
      >
        <gl-dropdown-item
          v-for="page in pages"
          :key="page.scope"
          is-check-item
          :is-checked="page.isActive"
          @click="onChangePage(page.scope)"
          >{{ page.name }}</gl-dropdown-item
        >
      </gl-dropdown>
      <gl-alert v-if="notice != ''" :dismissible="false">
        {{ notice }}
      </gl-alert>
      <insights-page :query-endpoint="queryEndpoint" :page-config="activePage" />
    </div>
    <gl-empty-state
      v-else
      :title="emptyState.title"
      :description="emptyState.description"
      :svg-path="emptyState.svgPath"
    />
  </div>
</template>
