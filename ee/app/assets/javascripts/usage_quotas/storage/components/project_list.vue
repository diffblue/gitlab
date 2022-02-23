<script>
import { PROJECT_TABLE_LABEL_PROJECT, PROJECT_TABLE_LABEL_USAGE } from '../constants';
import CollapsibleProjectStorageDetail from './collapsible_project_storage_detail.vue';
import ProjectsSkeletonLoader from './projects_skeleton_loader.vue';

export default {
  name: 'ProjectList',
  components: {
    CollapsibleProjectStorageDetail,
    ProjectsSkeletonLoader,
  },
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
    usageLabel: {
      type: String,
      required: false,
      default: PROJECT_TABLE_LABEL_USAGE,
    },
  },
  i18n: {
    PROJECT_TABLE_LABEL_PROJECT,
  },
};
</script>

<template>
  <div>
    <div
      class="gl-responsive-table-row table-row-header gl-border-t-solid gl-border-t-1 gl-border-gray-100 gl-mt-5 gl-line-height-normal gl-text-black-normal gl-font-base"
      role="row"
    >
      <div class="table-section section-70 gl-font-weight-bold" role="columnheader">
        {{ $options.i18n.PROJECT_TABLE_LABEL_PROJECT }}
      </div>
      <div
        class="table-section section-30 gl-font-weight-bold"
        role="columnheader"
        data-testid="usage-label"
      >
        {{ usageLabel }}
      </div>
    </div>
    <projects-skeleton-loader v-if="isLoading" />
    <collapsible-project-storage-detail
      v-for="project in projects"
      v-else
      :key="project.id"
      :project="project"
      :additional-purchased-storage-size="additionalPurchasedStorageSize"
    />
  </div>
</template>
