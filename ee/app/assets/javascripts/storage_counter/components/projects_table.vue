<script>
import { SEARCH_DEBOUNCE_MS } from '~/ref/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Project from './project.vue';
import ProjectsSkeletonLoader from './projects_skeleton_loader.vue';

export default {
  components: {
    Project,
    ProjectsSkeletonLoader,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    projects: {
      type: Array,
      required: true,
    },
    additionalPurchasedStorageSize: {
      type: Number,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  searchDebounceValue: SEARCH_DEBOUNCE_MS,
};
</script>

<template>
  <div>
    <div
      class="gl-responsive-table-row table-row-header gl-border-t-solid gl-border-t-1 gl-border-gray-100 gl-mt-5 gl-line-height-normal gl-text-black-normal gl-font-base"
      role="row"
    >
      <div class="table-section section-70 gl-font-weight-bold" role="columnheader">
        {{ __('Project') }}
      </div>
      <div class="table-section section-30 gl-font-weight-bold" role="columnheader">
        {{ __('Usage') }}
      </div>
    </div>
    <projects-skeleton-loader v-if="isLoading" />
    <template v-else>
      <project
        v-for="project in projects"
        :key="project.id"
        :project="project"
        :additional-purchased-storage-size="additionalPurchasedStorageSize"
      />
    </template>
  </div>
</template>
