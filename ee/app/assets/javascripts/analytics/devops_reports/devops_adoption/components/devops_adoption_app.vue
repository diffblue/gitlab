<script>
import { GlAlert, GlTabs, GlTab } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import DevopsScore from '~/analytics/devops_reports/components/devops_score.vue';
import API from '~/api';
import dateformat from '~/lib/dateformat';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import {
  I18N_GROUPS_QUERY_ERROR,
  I18N_ENABLED_NAMESPACE_QUERY_ERROR,
  I18N_ENABLE_NAMESPACE_MUTATION_ERROR,
  DATE_TIME_FORMAT,
  DEFAULT_POLLING_INTERVAL,
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  TRACK_ADOPTION_TAB_CLICK_EVENT,
  TRACK_DEVOPS_SCORE_TAB_CLICK_EVENT,
} from '../constants';
import bulkEnableDevopsAdoptionNamespacesMutation from '../graphql/mutations/bulk_enable_devops_adoption_namespaces.mutation.graphql';
import devopsAdoptionEnabledNamespacesQuery from '../graphql/queries/devops_adoption_enabled_namespaces.query.graphql';
import getGroupsQuery from '../graphql/queries/get_groups.query.graphql';
import {
  addEnabledNamespacesToCache,
  deleteEnabledNamespacesFromCache,
} from '../utils/cache_updates';
import { shouldPollTableData } from '../utils/helpers';
import DevopsAdoptionAddDropdown from './devops_adoption_add_dropdown.vue';
import DevopsAdoptionOverview from './devops_adoption_overview.vue';
import DevopsAdoptionSection from './devops_adoption_section.vue';

export default {
  name: 'DevopsAdoptionApp',
  components: {
    GlAlert,
    DevopsAdoptionAddDropdown,
    DevopsAdoptionSection,
    DevopsAdoptionOverview,
    DevopsScore,
    GlTabs,
    GlTab,
  },
  mixins: [Tracking.mixin()],
  inject: {
    isGroup: {
      default: false,
    },
    groupGid: {
      default: null,
    },
  },
  trackDevopsTabClickEvent: TRACK_ADOPTION_TAB_CLICK_EVENT,
  trackDevopsScoreTabClickEvent: TRACK_DEVOPS_SCORE_TAB_CLICK_EVENT,
  devopsAdoptionTableConfiguration: DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  data() {
    return {
      hasSubgroups: undefined,
      isLoadingEnableGroup: false,
      requestCount: 0,
      openModal: false,
      errors: [],
      groups: {
        nodes: [],
        pageInfo: null,
      },
      pollingTableData: null,
      enabledNamespaceQueryVariables: {
        displayNamespaceId: this.isGroup ? this.groupGid : null,
      },
      adoptionTabClicked: false,
      devopsScoreTabClicked: false,
      selectedTab: 0,
      groupsSearchTerm: '',
    };
  },
  apollo: {
    devopsAdoptionEnabledNamespaces: {
      query: devopsAdoptionEnabledNamespacesQuery,
      context: {
        isSingleRequest: true,
      },
      variables() {
        return this.enabledNamespaceQueryVariables;
      },
      result({ data }) {
        if (this.isGroup) {
          const groupEnabled = data.devopsAdoptionEnabledNamespaces.nodes.some(
            ({ namespace: { id } }) => id === this.groupGid,
          );

          if (!groupEnabled) {
            this.enableGroup();
          }
        }
      },
      error(error) {
        this.handleError(I18N_ENABLED_NAMESPACE_QUERY_ERROR, error);
      },
    },
    groups: {
      query: getGroupsQuery,
      context: {
        isSingleRequest: true,
      },
      variables() {
        return {
          search: this.groupsSearchTerm,
        };
      },
      result({ data }) {
        if (!data) {
          return;
        }
        if (this.hasSubgroups === undefined) {
          this.hasSubgroups = data.groups?.nodes?.length > 0;
        }
      },
      error(error) {
        this.handleError(I18N_GROUPS_QUERY_ERROR, error);
      },
    },
  },
  computed: {
    isAdmin() {
      return !this.isGroup;
    },
    hasGroupData() {
      return Boolean(this.groups?.nodes?.length);
    },
    hasEnabledNamespaceData() {
      return Boolean(this.devopsAdoptionEnabledNamespaces?.nodes?.length);
    },
    hasLoadingError() {
      return this.errors.length;
    },
    timestamp() {
      return dateformat(
        this.devopsAdoptionEnabledNamespaces?.nodes[0]?.latestSnapshot?.recordedAt,
        DATE_TIME_FORMAT,
      );
    },
    isLoading() {
      return (
        this.$apollo.queries.groups.loading ||
        this.isLoadingEnableGroup ||
        this.$apollo.queries.devopsAdoptionEnabledNamespaces.loading
      );
    },
    isLoadingAdoptionData() {
      return (
        this.isLoadingEnableGroup || this.$apollo.queries.devopsAdoptionEnabledNamespaces.loading
      );
    },
    tabIndexValues() {
      const tabs = [
        'overview',
        ...this.$options.devopsAdoptionTableConfiguration.map((item) => item.tab),
      ];

      return this.isGroup ? tabs : [...tabs, 'devops-score'];
    },
    availableGroups() {
      return this.groups?.nodes || [];
    },
    enabledNamespaces() {
      return this.devopsAdoptionEnabledNamespaces?.nodes || [];
    },
  },
  created() {
    this.selectTab();
    this.startPollingTableData();
  },
  beforeDestroy() {
    clearInterval(this.pollingTableData);
  },
  methods: {
    openAddRemoveModal() {
      this.$refs.addRemoveModal.openModal();
    },
    enableGroup() {
      this.isLoadingEnableGroup = true;

      this.$apollo
        .mutate({
          mutation: bulkEnableDevopsAdoptionNamespacesMutation,
          variables: {
            namespaceIds: [this.groupGid],
            displayNamespaceId: this.groupGid,
          },
          update: (store, { data }) => {
            const {
              bulkEnableDevopsAdoptionNamespaces: { enabledNamespaces, errors },
            } = data;

            if (errors.length) {
              this.handleError(I18N_ENABLE_NAMESPACE_MUTATION_ERROR, errors);
            } else {
              this.addEnabledNamespacesToCache(enabledNamespaces);
            }
          },
        })
        .catch((error) => {
          this.handleError(I18N_ENABLE_NAMESPACE_MUTATION_ERROR, error);
        })
        .finally(() => {
          this.isLoadingEnableGroup = false;
        });
    },
    pollTableData() {
      const shouldPoll = shouldPollTableData({
        enabledNamespaces: this.devopsAdoptionEnabledNamespaces.nodes,
        openModal: this.openModal,
      });

      if (shouldPoll) {
        this.$apollo.queries.devopsAdoptionEnabledNamespaces.refetch();
      }
    },
    trackModalOpenState(state) {
      this.openModal = state;
    },
    startPollingTableData() {
      this.pollingTableData = setInterval(this.pollTableData, DEFAULT_POLLING_INTERVAL);
    },
    handleError(message, error) {
      this.errors.push(message);
      Sentry.captureException(error);
    },
    setGroupsSearchTerm(searchTerm = '') {
      this.groupsSearchTerm = searchTerm;
    },
    addEnabledNamespacesToCache(enabledNamespaces) {
      const { cache } = this.$apollo.getClient();

      addEnabledNamespacesToCache(cache, enabledNamespaces, this.enabledNamespaceQueryVariables);
    },
    deleteEnabledNamespacesFromCache(ids) {
      const { cache } = this.$apollo.getClient();

      deleteEnabledNamespacesFromCache(cache, ids, this.enabledNamespaceQueryVariables);
    },
    selectTab() {
      const [value] = getParameterValues('tab');

      if (value) {
        this.selectedTab = this.tabIndexValues.indexOf(value);
      }
    },
    onTabChange(index) {
      if (index > 0) {
        if (index !== this.selectedTab) {
          const path = mergeUrlParams(
            { tab: this.tabIndexValues[index] },
            window.location.pathname,
          );
          updateHistory({ url: path, title: window.title });
        }
      } else {
        updateHistory({ url: window.location.pathname, title: window.title });
      }

      this.selectedTab = index;
    },
    trackDevopsScoreTabClick() {
      if (!this.devopsScoreTabClicked) {
        API.trackRedisHllUserEvent(this.$options.trackDevopsScoreTabClickEvent);
        this.trackSnowplowEvent(this.$options.trackDevopsScoreTabClickEvent);

        this.devopsScoreTabClicked = true;
      }
    },
    trackDevopsTabClick() {
      if (!this.adoptionTabClicked) {
        API.trackRedisHllUserEvent(this.$options.trackDevopsTabClickEvent);
        this.trackSnowplowEvent(this.$options.trackDevopsTabClickEvent);

        this.adoptionTabClicked = true;
      }
    },

    trackSnowplowEvent(event) {
      this.track('click_tab', {
        label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
        context: {
          schema: 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-0',
          data: {
            event_name: event,
            data_source: 'redis_hll',
          },
        },
      });
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs :value="selectedTab" @input="onTabChange">
      <gl-tab data-testid="devops-overview-tab">
        <template #title>{{ s__('DevopsReport|Overview') }}</template>
        <devops-adoption-overview
          :loading="isLoadingAdoptionData"
          :data="devopsAdoptionEnabledNamespaces"
          :timestamp="timestamp"
          @enabledNamespacesRemoved="deleteEnabledNamespacesFromCache"
        />
      </gl-tab>

      <gl-tab
        v-for="tab in $options.devopsAdoptionTableConfiguration"
        :key="tab.title"
        data-testid="devops-adoption-tab"
        @click="trackDevopsTabClick"
      >
        <template #title>{{ tab.title }}</template>
        <div v-if="hasLoadingError">
          <template v-for="(error, key) in errors">
            <gl-alert v-if="error" :key="key" variant="danger" :dismissible="false" class="gl-mt-3">
              {{ error }}
            </gl-alert>
          </template>
        </div>

        <devops-adoption-section
          v-else
          :is-loading="isLoadingAdoptionData"
          :has-enabled-namespace-data="hasEnabledNamespaceData"
          :timestamp="timestamp"
          :has-group-data="hasGroupData"
          :cols="tab.cols"
          :enabled-namespaces="devopsAdoptionEnabledNamespaces"
          :search-term="groupsSearchTerm"
          :groups="availableGroups"
          :is-loading-groups="$apollo.queries.groups.loading"
          :has-subgroups="hasSubgroups"
          @enabledNamespacesRemoved="deleteEnabledNamespacesFromCache"
          @fetchGroups="setGroupsSearchTerm"
          @enabledNamespacesAdded="addEnabledNamespacesToCache"
          @trackModalOpenState="trackModalOpenState"
        />
      </gl-tab>

      <gl-tab v-if="isAdmin" data-testid="devops-score-tab" @click="trackDevopsScoreTabClick">
        <template #title>{{ s__('DevopsReport|DevOps Score') }}</template>
        <devops-score />
      </gl-tab>

      <template #tabs-end>
        <span
          class="nav-item gl-align-self-center gl-flex-grow-1 gl-display-none gl-md-display-block"
          align="right"
        >
          <devops-adoption-add-dropdown
            :search-term="groupsSearchTerm"
            :groups="availableGroups"
            :enabled-namespaces="devopsAdoptionEnabledNamespaces"
            :is-loading-groups="$apollo.queries.groups.loading"
            :has-subgroups="hasSubgroups"
            @fetchGroups="setGroupsSearchTerm"
            @enabledNamespacesAdded="addEnabledNamespacesToCache"
            @enabledNamespacesRemoved="deleteEnabledNamespacesFromCache"
          />
        </span>
      </template>
    </gl-tabs>
  </div>
</template>
