<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlLoadingIcon } from '@gitlab/ui';

import { DEFAULT_PAGE_SIZE, FilterState } from '../constants';

export default {
  components: {
    GlSkeletonLoading,
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
      return this.requirementsCount[FilterState.all];
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
  <ul
    v-if="totalRequirements && currentTabCount"
    class="content-list issuable-list issues-list requirements-list-loading"
  >
    <li v-for="(i, index) in Array(loaderCount).fill()" :key="index" class="issue requirement">
      <gl-skeleton-loading :lines="2" class="pt-2" />
    </li>
  </ul>
  <gl-loading-icon v-else size="lg" class="mt-3" />
</template>
