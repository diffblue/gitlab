<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { __ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { COMPLIANCE_TAB_COOKIE_KEY } from '../constants';
import { mapDashboardToDrawerData } from '../utils';
import MergeRequestDrawer from './drawer.vue';
import EmptyState from './empty_state.vue';
import MergeRequestsGrid from './merge_requests/grid.vue';
import MergeCommitsExportButton from './merge_requests/merge_commits_export_button.vue';

export default {
  name: 'ComplianceDashboard',
  components: {
    MergeRequestDrawer,
    MergeRequestsGrid,
    EmptyState,
    GlTab,
    GlTabs,
    MergeCommitsExportButton,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    mergeRequests: {
      type: Array,
      required: true,
    },
    isLastPage: {
      type: Boolean,
      required: false,
      default: false,
    },
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showDrawer: false,
      drawerMergeRequest: {},
      drawerProject: {},
    };
  },
  computed: {
    hasMergeRequests() {
      return this.mergeRequests.length > 0;
    },
    hasMergeCommitsCsvExportPath() {
      return this.mergeCommitsCsvExportPath !== '';
    },
    drawerMergeRequests() {
      return this.mergeRequests.map(mapDashboardToDrawerData);
    },
  },
  methods: {
    showTabs() {
      return Cookies.get(COMPLIANCE_TAB_COOKIE_KEY) === 'true';
    },
    toggleDrawer(mergeRequest) {
      if (this.showDrawer && mergeRequest.id === this.drawerMergeRequest.id) {
        this.closeDrawer();
      } else {
        this.openDrawer(this.drawerMergeRequests.find((mr) => mr.id === mergeRequest.id));
      }
    },
    openDrawer(data) {
      this.showDrawer = true;
      this.drawerMergeRequest = data.mergeRequest;
      this.drawerProject = data.project;
    },
    closeDrawer() {
      this.showDrawer = false;
      this.drawerMergeRequest = {};
      this.drawerProject = {};
    },
  },
  DRAWER_Z_INDEX,
  strings: {
    heading: __('Compliance report'),
    subheading: __('Here you will find recent merge request activity'),
    mergeRequestsTabLabel: __('Merge Requests'),
  },
};
</script>

<template>
  <div v-if="hasMergeRequests" class="compliance-dashboard">
    <header>
      <div class="gl-mt-5 d-flex">
        <h4 class="gl-flex-grow-1 gl-my-0">{{ $options.strings.heading }}</h4>
        <merge-commits-export-button
          v-if="hasMergeCommitsCsvExportPath"
          :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
        />
      </div>
      <p>{{ $options.strings.subheading }}</p>
    </header>

    <gl-tabs v-if="showTabs()">
      <gl-tab>
        <template #title>
          <span>{{ $options.strings.mergeRequestsTabLabel }}</span>
        </template>
        <merge-requests-grid
          :merge-requests="mergeRequests"
          :is-last-page="isLastPage"
          @toggleDrawer="toggleDrawer"
        />
      </gl-tab>
    </gl-tabs>
    <merge-requests-grid
      v-else
      :merge-requests="mergeRequests"
      :is-last-page="isLastPage"
      @toggleDrawer="toggleDrawer"
    />
    <merge-request-drawer
      :show-drawer="showDrawer"
      :merge-request="drawerMergeRequest"
      :project="drawerProject"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDrawer"
    />
  </div>
  <empty-state v-else :image-path="emptyStateSvgPath" />
</template>
