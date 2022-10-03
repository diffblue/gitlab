<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { getStorageTypesFromProjectStatistics } from '../utils';
import { PROJECT_TABLE_LABEL_PROJECT, PROJECT_TABLE_LABEL_USAGE } from '../constants';
import ProjectStorageDetail from './project_storage_detail.vue';

export default {
  name: 'CollapsibleProjectStorageDetail',
  components: {
    GlIcon,
    GlLink,
    ProjectAvatar,
    ProjectStorageDetail,
  },
  inject: ['helpLinks'],
  props: {
    project: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      isOpen: false,
    };
  },
  computed: {
    name() {
      return this.project.nameWithNamespace;
    },
    storageSize() {
      return numberToHumanSize(this.project.statistics.storageSize);
    },
    iconName() {
      return this.isOpen ? 'chevron-down' : 'chevron-right';
    },
    projectStorageTypes() {
      return getStorageTypesFromProjectStatistics(this.project.statistics, this.helpLinks);
    },
  },
  methods: {
    toggleProject(e) {
      const NO_EXPAND_CLS = 'js-project-link';
      const targetClasses = e.target.classList;

      if (targetClasses.contains(NO_EXPAND_CLS)) {
        return;
      }
      this.isOpen = !this.isOpen;
    },
  },
  i18n: {
    PROJECT_TABLE_LABEL_PROJECT,
    PROJECT_TABLE_LABEL_USAGE,
  },
};
</script>
<template>
  <div>
    <div
      class="gl-responsive-table-row gl-border-solid gl-border-b-1 gl-pt-3 gl-pb-3 gl-border-b-gray-100 gl-hover-bg-blue-50 gl-hover-border-blue-200 gl-hover-cursor-pointer"
      role="row"
      data-testid="projectTableRow"
      data-qa-selector="project"
      @click="toggleProject"
    >
      <div
        class="table-section gl-white-space-normal! gl-sm-flex-wrap section-70 gl-text-truncate"
        role="gridcell"
      >
        <div class="table-mobile-header gl-font-weight-bold" role="rowheader">
          {{ $options.i18n.PROJECT_TABLE_LABEL_PROJECT }}
        </div>
        <div class="table-mobile-content gl-display-flex gl-align-items-center">
          <div class="gl-display-flex gl-mr-3 gl-align-items-center">
            <gl-icon :size="12" :name="iconName" />
            <gl-icon name="bookmark" />
          </div>
          <project-avatar
            :project-id="project.id"
            :project-name="project.name"
            :project-avatar-url="project.avatarUrl"
            :size="32"
            :alt="project.name"
            class="gl-mr-3"
          />
          <gl-link
            :href="project.webUrl"
            class="js-project-link gl-font-weight-bold gl-text-gray-900!"
            >{{ name }}</gl-link
          >
        </div>
      </div>
      <div
        class="table-section gl-white-space-normal! gl-sm-flex-wrap section-30 gl-text-truncate"
        role="gridcell"
      >
        <div class="table-mobile-header gl-font-weight-bold" role="rowheader">
          {{ $options.i18n.PROJECT_TABLE_LABEL_USAGE }}
        </div>
        <div class="table-mobile-content gl-text-gray-900" data-qa-selector="project_storage_used">
          {{ storageSize }}
        </div>
      </div>
    </div>
    <project-storage-detail v-if="isOpen" :storage-types="projectStorageTypes" />
  </div>
</template>
