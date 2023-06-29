<script>
import Vue from 'vue';
import {
  GlDrawer,
  GlBadge,
  GlIcon,
  GlSkeletonLoader,
  GlEmptyState,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import summaryNotesQuery from '../queries/summary_notes.query.graphql';
import SummaryNoteWrapper from './summary_note_wrapper.vue';
import SummaryNote from './summary_note.vue';

export const INITIAL_STATE = {
  open: false,
  summaryNotes: { nodes: [], pageInfo: {} },
  afterCursor: '',
  loadingCount: 0,
  fetchingMore: false,
};
export const summaryState = Vue.observable({
  ...INITIAL_STATE,
  toggleOpen() {
    summaryState.open = !summaryState.open;
  },
});

export default {
  apollo: {
    summaryNotes: {
      query: summaryNotesQuery,
      skip() {
        return !this.open;
      },
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.iid,
          after: '',
        };
      },
      update: (d) => d.project?.mergeRequest?.diffLlmSummaries,
      watchLoading(isLoading) {
        if (!isLoading) this.loadingCount += 1;
      },
    },
  },
  components: {
    GlDrawer,
    GlBadge,
    GlIcon,
    GlSkeletonLoader,
    GlEmptyState,
    GlIntersectionObserver,
    GlLoadingIcon,
    SummaryNoteWrapper,
    SummaryNote,
  },
  inject: {
    projectPath: {
      default: '',
    },
    iid: {
      default: '',
    },
    emptyStateSvg: {
      default: '',
    },
  },
  data() {
    return summaryState;
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    notes() {
      return this.summaryNotes?.nodes;
    },
  },
  methods: {
    async fetchMore() {
      if (!this.summaryNotes?.pageInfo.hasNextPage || this.fetchingMore) return;

      this.fetchingMore = true;

      await this.$apollo.queries.summaryNotes.fetchMore({
        variables: {
          projectPath: this.projectPath,
          iid: this.iid,
          after: this.summaryNotes.pageInfo.endCursor,
        },
      });

      this.fetchingMore = false;
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="toggleOpen"
  >
    <template #title>
      <div class="gl-display-flex gl-align-items-center">
        <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-mr-3" />
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">
          {{ s__('MergeRequest|Summary notes') }}
        </h2>
        <div>
          <gl-badge variant="neutral" class="gl-ml-3">{{ __('Experiment') }}</gl-badge>
        </div>
      </div>
    </template>
    <div class="gl-text-center gl-p-4! gl-bg-gray-50 gl-text-gray-600">
      {{ s__('MergeRequest|Summaries are written by AI') }}
    </div>
    <div :class="{ 'gl-display-flex': !notes.length }" style="min-height: calc(100% - 41px)">
      <summary-note-wrapper v-if="loadingCount < 1">
        <template #title>
          <div style="width: 100px">
            <gl-skeleton-loader :width="100" :height="10">
              <rect x="0" y="0" width="100" height="10" rx="4" />
            </gl-skeleton-loader>
          </div>
        </template>
        <template #created>
          <div style="width: 50px">
            <gl-skeleton-loader :width="50" :height="10">
              <rect x="0" y="0" width="50" height="10" rx="4" />
            </gl-skeleton-loader>
          </div>
        </template>
        <template #content>
          <gl-skeleton-loader :width="200" />
        </template>
        <template #feedback>
          <div style="width: 38px">
            <gl-skeleton-loader :width="38" :height="10">
              <rect x="0" y="0" width="10" height="10" rx="4" />
              <rect x="14" y="0" width="10" height="10" rx="4" />
              <rect x="28" y="0" width="10" height="10" rx="4" />
            </gl-skeleton-loader>
          </div>
        </template>
        <template #feedback-link>
          <div style="width: 100px">
            <gl-skeleton-loader :width="100" :height="10">
              <rect x="0" y="0" width="100" height="10" rx="4" />
            </gl-skeleton-loader>
          </div>
        </template>
      </summary-note-wrapper>

      <template v-else>
        <gl-empty-state
          v-if="!notes.length"
          :svg-path="emptyStateSvg"
          :svg-height="145"
          :title="__('Merge request summaries')"
          :description="
            __(
              'Summary will be generated with the next push to this merge request and will appear here.',
            )
          "
          class="gl-mt-0! gl-align-self-center"
        />
        <template v-else>
          <summary-note
            v-for="summary in notes"
            :key="summary.mergeRequestDiffId"
            :summary="summary"
            data-testid="summary-note"
          />
          <gl-loading-icon v-if="fetchingMore" />
          <gl-intersection-observer @appear="fetchMore" />
        </template>
      </template>
    </div>
  </gl-drawer>
</template>
