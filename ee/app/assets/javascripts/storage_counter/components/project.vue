<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { numberToHumanSize, isOdd } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/deprecated_project_avatar/default.vue';
import StorageRow from './storage_row.vue';

export default {
  components: {
    GlIcon,
    GlLink,
    ProjectAvatar,
    StorageRow,
  },
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
    projectAvatar() {
      const { name, id, avatarUrl, webUrl } = this.project;
      return {
        name,
        id: Number(getIdFromGraphQLId(id)),
        avatar_url: avatarUrl,
        path: webUrl,
      };
    },
    name() {
      return this.project.nameWithNamespace;
    },
    storageSize() {
      return numberToHumanSize(this.project.statistics.storageSize);
    },
    iconName() {
      return this.isOpen ? 'angle-down' : 'angle-right';
    },
    statistics() {
      const statisticsCopy = { ...this.project.statistics };
      delete statisticsCopy.storageSize;
      // eslint-disable-next-line no-underscore-dangle
      delete statisticsCopy.__typename;
      delete statisticsCopy.commitCount;

      return statisticsCopy;
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
    getFormattedName(name) {
      return this.$options.i18nStatisticsMap[name];
    },
    isOdd(num) {
      return isOdd(num);
    },
    /**
     * Some values can be `nil`
     * for those, we send 0 instead
     */
    getValue(val) {
      return val || 0;
    },
  },
  i18nStatisticsMap: {
    repositorySize: s__('UsageQuota|Repository'),
    lfsObjectsSize: s__('UsageQuota|LFS Storage'),
    buildArtifactsSize: s__('UsageQuota|Artifacts'),
    packagesSize: s__('UsageQuota|Packages'),
    wikiSize: s__('UsageQuota|Wiki'),
    snippetsSize: s__('UsageQuota|Snippets'),
    uploadsSize: s__('UsageQuota|Uploads'),
  },
};
</script>
<template>
  <div>
    <div
      class="gl-responsive-table-row gl-border-solid gl-border-b-1 gl-pt-3 gl-pb-3 gl-border-b-gray-100 gl-hover-bg-blue-50 gl-hover-border-blue-200 gl-hover-cursor-pointer"
      role="row"
      data-testid="projectTableRow"
      @click="toggleProject"
    >
      <div
        class="table-section gl-white-space-normal! gl-sm-flex-wrap section-70 gl-text-truncate"
        role="gridcell"
      >
        <div class="table-mobile-header gl-font-weight-bold" role="rowheader">
          {{ __('Project') }}
        </div>
        <div class="table-mobile-content gl-display-flex gl-align-items-center">
          <div class="gl-display-flex gl-mr-3 gl-align-items-center">
            <gl-icon :size="12" :name="iconName" class="gl-mr-2" />
            <gl-icon name="bookmark" />
          </div>
          <div>
            <project-avatar :project="projectAvatar" :size="32" />
          </div>
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
          {{ __('Usage') }}
        </div>
        <div class="table-mobile-content gl-text-gray-900">{{ storageSize }}</div>
      </div>
    </div>

    <template v-if="isOpen">
      <storage-row
        v-for="(value, statisticsName, index) in statistics"
        :key="index"
        :name="getFormattedName(statisticsName)"
        :value="getValue(value)"
        :class="{ 'gl-bg-gray-10': isOdd(index) }"
      />
    </template>
  </div>
</template>
