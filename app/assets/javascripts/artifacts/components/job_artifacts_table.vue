<script>
import {
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlButtonGroup,
  GlButton,
  GlBadge,
  GlIcon,
  GlPagination,
} from '@gitlab/ui';
import { createAlert } from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import { totalArtifactsSizeForJob, mapArchivesToJobNodes, mapBooleansToJobNodes } from '../utils';
import { STATUS_BADGE_VARIANTS, JOBS_PER_PAGE, INITIAL_PAGINATION_STATE, i18n } from '../constants';
import ArtifactsTableRowDetails from './artifacts_table_row_details.vue';

export default {
  name: 'JobArtifactsTable',
  components: {
    GlLoadingIcon,
    GlTable,
    GlLink,
    GlButtonGroup,
    GlButton,
    GlBadge,
    GlIcon,
    GlPagination,
    CiIcon,
    TimeAgo,
    ArtifactsTableRowDetails,
  },
  inject: ['projectPath'],
  apollo: {
    jobArtifacts: {
      query: getJobArtifactsQuery,
      variables() {
        return this.queryVariables;
      },
      update({ project: { jobs: { nodes = [], pageInfo = {}, count = 0 } = {} } }) {
        return {
          nodes: nodes.map(mapArchivesToJobNodes).map(mapBooleansToJobNodes),
          count,
          pageInfo,
        };
      },
      error() {
        createAlert({
          message: i18n.fetchArtifactsError,
        });
      },
    },
  },
  data() {
    return {
      jobArtifacts: {
        nodes: [],
        count: 0,
        pageInfo: {},
      },
      pagination: INITIAL_PAGINATION_STATE,
    };
  },
  computed: {
    queryVariables() {
      return {
        projectPath: this.projectPath,
        firstPageSize: this.pagination.firstPageSize,
        lastPageSize: this.pagination.lastPageSize,
        prevPageCursor: this.pagination.prevPageCursor,
        nextPageCursor: this.pagination.nextPageCursor,
      };
    },
    showPagination() {
      return this.jobArtifacts.count > JOBS_PER_PAGE;
    },
    prevPage() {
      return Number(this.jobArtifacts.pageInfo.hasPreviousPage);
    },
    nextPage() {
      return Number(this.jobArtifacts.pageInfo.hasNextPage);
    },
  },
  methods: {
    refetchArtifacts() {
      this.$apollo.queries.jobArtifacts.refetch();
    },
    artifactsSize(item) {
      return totalArtifactsSizeForJob(item);
    },
    pipelineId(item) {
      const id = getIdFromGraphQLId(item.pipeline.id);
      return `#${id}`;
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.jobArtifacts.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          ...INITIAL_PAGINATION_STATE,
          nextPageCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          lastPageSize: JOBS_PER_PAGE,
          firstPageSize: null,
          prevPageCursor: startCursor,
          currentPage: page,
        };
      }
    },
    handleRowToggle(toggleDetails, hasArtifacts) {
      if (!hasArtifacts) return;
      toggleDetails();
    },
  },
  fields: [
    {
      key: 'artifacts',
      label: i18n.artifactsLabel,
      thClass: 'gl-w-quarter',
    },
    {
      key: 'job',
      label: i18n.jobLabel,
      thClass: 'gl-w-35p',
    },
    {
      key: 'size',
      label: i18n.sizeLabel,
      thClass: 'gl-w-15p gl-text-right',
      tdClass: 'gl-text-right',
    },
    {
      key: 'created',
      label: i18n.createdLabel,
      thClass: 'gl-w-eighth gl-text-center',
      tdClass: 'gl-text-center',
    },
    {
      key: 'actions',
      label: '',
      thClass: 'gl-w-eighth',
      tdClass: 'gl-text-right',
    },
  ],
  STATUS_BADGE_VARIANTS,
  i18n,
};
</script>
<template>
  <div>
    <gl-table
      :items="jobArtifacts.nodes"
      :fields="$options.fields"
      :busy="$apollo.queries.jobArtifacts.loading"
      stacked="sm"
      details-td-class="gl-bg-gray-10! gl-p-0! gl-overflow-auto"
    >
      <template #table-busy>
        <gl-loading-icon size="lg" />
      </template>
      <template
        #cell(artifacts)="{ item: { artifacts, hasArtifacts }, toggleDetails, detailsShowing }"
      >
        <span
          :class="{ 'gl-cursor-pointer': hasArtifacts }"
          data-testid="job-artifacts-count"
          @click="handleRowToggle(toggleDetails, hasArtifacts)"
        >
          <gl-icon
            v-if="hasArtifacts"
            :name="detailsShowing ? 'chevron-down' : 'chevron-right'"
            class="gl-mr-2"
          />
          <strong>
            {{ n__('%d file', '%d files', artifacts.nodes.length) }}
          </strong>
        </span>
      </template>
      <template #cell(job)="{ item }">
        <span class="gl-display-inline-flex gl-align-items-center gl-w-full gl-mb-4">
          <span data-testid="job-artifacts-job-status">
            <ci-icon v-if="item.succeeded" :status="item.detailedStatus" class="gl-mr-3" />
            <gl-badge
              v-else
              :icon="item.detailedStatus.icon"
              :variant="$options.STATUS_BADGE_VARIANTS[item.detailedStatus.group]"
              class="gl-mr-3"
            >
              {{ item.detailedStatus.label }}
            </gl-badge>
          </span>
          <gl-link :href="item.webPath" class="gl-font-weight-bold">
            {{ item.name }}
          </gl-link>
        </span>
        <span class="gl-display-inline-flex">
          <gl-icon name="pipeline" class="gl-mr-2" />
          <gl-link
            :href="item.pipeline.path"
            class="gl-text-black-normal gl-text-decoration-underline gl-mr-4"
          >
            {{ pipelineId(item) }}
          </gl-link>
          <gl-icon name="branch" class="gl-mr-2" />
          <gl-link
            :href="item.refPath"
            class="gl-text-black-normal gl-text-decoration-underline gl-mr-4"
          >
            {{ item.refName }}
          </gl-link>
          <gl-icon name="commit" class="gl-mr-2" />
          <gl-link
            :href="item.commitPath"
            class="gl-text-black-normal gl-text-decoration-underline gl-mr-4"
          >
            {{ item.shortSha }}
          </gl-link>
        </span>
      </template>
      <template #cell(size)="{ item }">
        <span data-testid="job-artifacts-size">{{ artifactsSize(item) }}</span>
      </template>
      <template #cell(created)="{ item }">
        <time-ago data-testid="job-artifacts-created" :time="item.finishedAt" />
      </template>
      <template #cell(actions)="{ item }">
        <gl-button-group>
          <gl-button
            icon="download"
            :disabled="!item.archive.downloadPath"
            :href="item.archive.downloadPath"
            :title="$options.i18n.download"
            :aria-label="$options.i18n.download"
            data-testid="job-artifacts-download-button"
          />
          <gl-button
            icon="folder-open"
            :title="$options.i18n.browse"
            :aria-label="$options.i18n.browse"
            data-testid="job-artifacts-browse-button"
            disabled
          />
          <gl-button
            icon="remove"
            :title="$options.i18n.delete"
            :aria-label="$options.i18n.delete"
            data-testid="job-artifacts-delete-button"
            disabled
          />
        </gl-button-group>
      </template>
      <template #row-details="{ item: { artifacts } }">
        <artifacts-table-row-details
          :artifacts="artifacts"
          :refetch-artifacts="refetchArtifacts"
          :query-variables="queryVariables"
        />
      </template>
    </gl-table>
    <gl-pagination
      v-if="showPagination"
      :value="pagination.currentPage"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-mt-3"
      @input="handlePageChange"
    />
  </div>
</template>
