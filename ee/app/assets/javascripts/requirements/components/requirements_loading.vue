<script>
import { GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { filterState } from '../constants';

export default {
  components: {
    GlSkeletonLoader,
    GlLoadingIcon,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    currentPage: {
      type: Number,
      required: true,
    },
    requirementsCount: {
      type: Object,
      required: true,
    },
  },
  computed: {
    currentTabCount() {
      return this.requirementsCount[this.filterBy];
    },
    totalRequirements() {
      return this.requirementsCount[filterState.all];
    },
    lastPage() {
      return Math.ceil(this.currentTabCount / DEFAULT_PAGE_SIZE);
    },
    loaderCount() {
      if (this.currentTabCount > DEFAULT_PAGE_SIZE && this.currentPage !== this.lastPage) {
        return DEFAULT_PAGE_SIZE;
      }
      return this.currentTabCount % DEFAULT_PAGE_SIZE || DEFAULT_PAGE_SIZE;
    },
  },
};
</script>

<template>
  <ul v-if="totalRequirements && currentTabCount" class="content-list issuable-list issues-list">
    <li v-for="(i, index) in Array(loaderCount).fill()" :key="index" class="issue requirement">
      <gl-skeleton-loader :lines="2" :width="800" :height="24" preserveAspectRatio="none" />
    </li>
  </ul>
  <gl-loading-icon v-else size="lg" class="mt-3" />
</template>
