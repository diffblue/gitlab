<script>
import { GlCard, GlEmptyState, GlLink, GlSkeletonLoader, GlTable } from '@gitlab/ui';
import Vue from 'vue';
import api from '~/api';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { joinPaths } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import getProjectsTestCoverage from '../graphql/queries/get_projects_test_coverage.query.graphql';
import SelectProjectsDropdown from './select_projects_dropdown.vue';

export default {
  name: 'TestCoverageTable',
  components: {
    GlCard,
    GlEmptyState,
    GlLink,
    GlSkeletonLoader,
    GlTable,
    SelectProjectsDropdown,
    TimeAgoTooltip,
  },
  inject: {
    groupFullPath: {
      default: '',
    },
  },
  apollo: {
    projects: {
      query: getProjectsTestCoverage,
      debounce: 500,
      variables() {
        return {
          groupFullPath: this.groupFullPath,
          projectIds: this.projectIdsToFetch,
        };
      },
      result({ data }) {
        const projects = data.group.projects.nodes;
        // Keep data from all queries so that we don't
        // fetch the same data more than once
        this.allCoverageData = [
          ...this.allCoverageData,
          ...projects
            .filter(({ id }) => !this.allCoverageData.some((project) => project.id === id))
            .map((project) => ({
              ...project,
              codeCoveragePath: joinPaths(
                gon.relative_url_root || '',
                `/${project.fullPath}/-/graphs/${project.repository.rootRef}/charts`,
              ),
            })),
        ];
      },
      update(data) {
        return data.group.projects.nodes;
      },
      error() {
        this.handleError();
      },
      watchLoading(isLoading) {
        this.isLoading = isLoading;
      },
      skip() {
        return this.skipQuery;
      },
    },
  },
  data() {
    return {
      allProjectsSelected: true,
      allCoverageData: [], // All data we have ever received whether selected or not
      hasError: false,
      isLoading: false,
      selectedProjectIds: {},
      projects: {},
    };
  },
  computed: {
    hasCoverageData() {
      return Boolean(this.selectedCoverageData.length);
    },
    skipQuery() {
      // Skip if we haven't selected any projects yet
      return !this.allProjectsSelected && !this.projectIdsToFetch.length;
    },
    /**
     * projectIdsToFetch is a subset of selectedProjectIds
     * The difference is that it only returns the projects
     * that we have selected but haven't requested yet
     */
    projectIdsToFetch() {
      if (this.allProjectsSelected) {
        return null;
      }
      // Get the IDs of the projects that we haven't requested yet
      return Object.keys(this.selectedProjectIds).filter(
        (id) => !this.allCoverageData.some((project) => project.id === id),
      );
    },
    selectedCoverageData() {
      if (this.allProjectsSelected) {
        return this.allCoverageData;
      }

      return this.allCoverageData.filter(({ id }) => this.selectedProjectIds[id]);
    },
    sortedCoverageData() {
      // Sort the table by most recently updated coverage report
      return [...this.selectedCoverageData].sort((a, b) => {
        if (a.codeCoverageSummary.lastUpdatedOn > b.codeCoverageSummary.lastUpdatedOn) {
          return -1;
        } else if (a.codeCoverageSummary.lastUpdatedOn < b.codeCoverageSummary.lastUpdatedOn) {
          return 1;
        }
        return 0;
      });
    },
  },
  methods: {
    handleError() {
      this.hasError = true;
    },
    onProjectClick() {
      api.trackRedisHllUserEvent(this.$options.servicePingProjectEvent);
    },
    selectAllProjects() {
      this.allProjectsSelected = true;
    },
    toggleProject({ id }) {
      if (this.allProjectsSelected) {
        // Reset all project selections to false
        this.allProjectsSelected = false;
        this.selectedProjectIds = Object.fromEntries(
          Object.entries(this.selectedProjectIds).map(([key]) => [key, false]),
        );
      }

      if (Object.prototype.hasOwnProperty.call(this.selectedProjectIds, id)) {
        Vue.set(this.selectedProjectIds, id, !this.selectedProjectIds[id]);
        return;
      }

      Vue.set(this.selectedProjectIds, id, true);
    },
  },
  tableFields: [
    {
      key: 'project',
      label: __('Project'),
    },
    {
      key: 'averageCoverage',
      label: s__('RepositoriesAnalytics|Coverage'),
    },
    {
      key: 'coverageCount',
      label: s__('RepositoriesAnalytics|Coverage Jobs'),
    },
    {
      key: 'lastUpdatedOn',
      label: s__('RepositoriesAnalytics|Last Update'),
    },
  ],
  text: {
    header: s__('RepositoriesAnalytics|Latest test coverage results'),
    emptyStateTitle: s__('RepositoriesAnalytics|Please select projects to display.'),
    emptyStateDescription: s__(
      'RepositoriesAnalytics|Please select a project or multiple projects to display their most recent test coverage data.',
    ),
  },
  LOADING_STATE: {
    rows: 4,
    height: 10,
    rx: 4,
    groupXs: [0, 95, 180, 330],
    widths: [90, 80, 145, 100],
    totalWidth: 430,
    totalHeight: 15,
  },
  averageCoverageFormatter: getFormatter(SUPPORTED_FORMATS.percentHundred),
  servicePingProjectEvent: 'i_testing_group_code_coverage_project_click_total',
};
</script>
<template>
  <gl-card>
    <template #header>
      <div class="gl-display-flex gl-justify-content-space-between">
        <h5>{{ $options.text.header }}</h5>
        <select-projects-dropdown
          class="gl-w-quarter"
          @projects-query-error="handleError"
          @select-all-projects="selectAllProjects"
          @select-project="toggleProject"
        />
      </div>
    </template>

    <template v-if="isLoading">
      <gl-skeleton-loader
        v-for="index in $options.LOADING_STATE.rows"
        :key="index"
        :width="$options.LOADING_STATE.totalWidth"
        :height="$options.LOADING_STATE.totalHeight"
        data-testid="test-coverage-loading-state"
      >
        <rect
          v-for="(x, xIndex) in $options.LOADING_STATE.groupXs"
          :key="`x-skeleton-${x}`"
          :width="$options.LOADING_STATE.widths[xIndex]"
          :height="$options.LOADING_STATE.height"
          :x="x"
          :y="0"
          :rx="$options.LOADING_STATE.rx"
        />
      </gl-skeleton-loader>
    </template>

    <gl-table
      v-else-if="hasCoverageData"
      data-testid="test-coverage-data-table"
      thead-class="thead-white"
      :fields="$options.tableFields"
      :items="sortedCoverageData"
    >
      <template #head(project)="data">
        <div>{{ data.label }}</div>
      </template>
      <template #head(averageCoverage)="data">
        <div>{{ data.label }}</div>
      </template>
      <template #head(coverageCount)="data">
        <div>{{ data.label }}</div>
      </template>
      <template #head(lastUpdatedOn)="data">
        <div>{{ data.label }}</div>
      </template>

      <template #cell(project)="{ item }">
        <gl-link
          target="_blank"
          :href="item.codeCoveragePath"
          :data-testid="`${item.id}-name`"
          @click.once="onProjectClick"
        >
          {{ item.name }}
        </gl-link>
      </template>
      <template #cell(averageCoverage)="{ item }">
        <div :data-testid="`${item.id}-average`">
          {{ $options.averageCoverageFormatter(item.codeCoverageSummary.averageCoverage, 2) }}
        </div>
      </template>
      <template #cell(coverageCount)="{ item }">
        <div :data-testid="`${item.id}-count`">{{ item.codeCoverageSummary.coverageCount }}</div>
      </template>
      <template #cell(lastUpdatedOn)="{ item }">
        <time-ago-tooltip
          :time="item.codeCoverageSummary.lastUpdatedOn"
          :data-testid="`${item.id}-date`"
        />
      </template>
    </gl-table>

    <gl-empty-state
      v-else
      class="gl-mt-3"
      :title="$options.text.emptyStateTitle"
      :description="$options.text.emptyStateDescription"
      data-testid="test-coverage-table-empty-state"
    />
  </gl-card>
</template>
