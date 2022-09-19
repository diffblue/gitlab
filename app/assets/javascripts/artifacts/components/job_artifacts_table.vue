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
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import destroyArtifactMutation from '../graphql/mutations/destroy_artifact.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import { totalArtifactsSizeForJob, mapArchivesToJobNodes } from '../utils';
import {
  JOB_STATUS_GROUP_SUCCESS,
  STATUS_BADGE_VARIANTS,
  JOBS_PER_PAGE,
  INITIAL_PAGINATION_STATE,
  i18n,
} from '../constants';
import ArtifactRow from './artifact_row.vue';

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
    DynamicScroller,
    DynamicScrollerItem,
    ArtifactRow,
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
          nodes: nodes.map(mapArchivesToJobNodes),
          count,
          pageInfo,
        };
      },
      error() {
        createFlash({
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
      deletingArtifactId: null,
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
    destroyArtifact(id) {
      this.deletingArtifactId = id;
      this.$apollo
        .mutate({
          mutation: destroyArtifactMutation,
          variables: { id },
          update: (store) => {
            removeArtifactFromStore(store, id, getJobArtifactsQuery, this.queryVariables);
          },
        })
        .catch(() => {
          createFlash({
            message: i18n.destroyArtifactError,
          });
          this.$apollo.queries.jobArtifacts.refetch();
        })
        .finally(() => {
          this.deletingArtifactId = null;
        });
    },
    artifactsSize(item) {
      return totalArtifactsSizeForJob(item);
    },
    jobSucceeded(item) {
      return item.detailedStatus.group === JOB_STATUS_GROUP_SUCCESS;
    },
    statusVariant(item) {
      return STATUS_BADGE_VARIANTS[item.detailedStatus.group];
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
    handleRowToggle(toggleDetails) {
      toggleDetails();
    },
  },
  fields: [
    {
      key: 'artifacts',
      label: s__('Artifacts|Artifacts'),
      thClass: 'gl-w-quarter',
    },
    {
      key: 'job',
      label: s__('Artifacts|Job'),
      thClass: 'gl-w-40p',
    },
    {
      key: 'size',
      label: s__('Artifacts|Size'),
      thClass: 'gl-w-10p gl-text-right',
      tdClass: 'gl-text-right',
    },
    {
      key: 'created',
      label: s__('Artifacts|Created'),
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
      details-td-class="gl-bg-gray-10! gl-p-0! gl-overflow-auto gl-min-h-0 gl-h-13"
    >
      <template #table-busy>
        <gl-loading-icon size="lg" />
      </template>
      <template #cell(artifacts)="{ item, toggleDetails, detailsShowing }">
        <span
          class="gl-cursor-pointer"
          data-testid="job-artifacts-count"
          @click="handleRowToggle(toggleDetails)"
        >
          <gl-icon v-if="detailsShowing" name="chevron-down" class="gl-mr-2" />
          <gl-icon v-else name="chevron-right" class="gl-mr-2" />
          <strong>
            {{ n__('%d file', '%d files', item.artifacts.nodes.length) }}
          </strong>
        </span>
      </template>
      <template #cell(job)="{ item }">
        <span class="gl-display-inline-flex gl-align-items-center gl-w-full gl-mb-4">
          <span data-testid="job-artifacts-job-status">
            <ci-icon v-if="jobSucceeded(item)" :status="item.detailedStatus" class="gl-mr-3" />
            <gl-badge
              v-else
              :icon="item.detailedStatus.icon"
              :variant="statusVariant(item)"
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
        <div style="max-height: 222px">
          <dynamic-scroller :items="artifacts.nodes" :min-item-size="64">
            <template #default="{ item, index, active }">
              <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
                <div
                  :class="{
                    'gl-border-b-solid gl-border-b-1 gl-border-gray-100':
                      index !== artifacts.nodes.length - 1,
                  }"
                  class="gl-py-5"
                >
                  <artifact-row
                    :artifact="item"
                    :deleting="item.id === deletingArtifactId"
                    @delete="destroyArtifact(item.id)"
                  />
                </div>
              </dynamic-scroller-item>
            </template>
          </dynamic-scroller>
        </div>
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
