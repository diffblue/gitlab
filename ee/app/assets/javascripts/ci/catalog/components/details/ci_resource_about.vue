<script>
import { GlIcon, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { n__, s__, sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSkeletonLoader,
  },
  props: {
    openIssuesCount: {
      required: false,
      type: Number,
      default: 0,
    },
    openMergeRequestsCount: {
      required: false,
      type: Number,
      default: 0,
    },
    isLoadingDetails: {
      required: true,
      type: Boolean,
    },
    isLoadingSharedData: {
      required: true,
      type: Boolean,
    },
    latestVersion: {
      required: false,
      type: Object,
      default: () => ({}),
    },
    webPath: {
      required: false,
      type: String,
      default: '',
    },
  },
  computed: {
    hasVersion() {
      return this.latestVersion;
    },
    lastReleaseText() {
      if (this.hasVersion) {
        return sprintf(this.$options.i18n.lastRelease, {
          date: this.releasedAt,
        });
      }

      return this.$options.i18n.lastReleaseMissing;
    },
    openIssuesText() {
      return n__('%d issue', '%d issues', this.openIssuesCount);
    },
    openMergeRequestText() {
      return n__('%d merge request', '%d merge requests', this.openMergeRequestsCount);
    },
    releasedAt() {
      return this.hasVersion && formatDate(this.latestVersion.releasedAt, 'yyyy-mm-dd');
    },
    projectInfoItems() {
      return [
        {
          icon: 'project',
          link: `${this.webPath}`,
          text: this.$options.i18n.projectLink,
          isLoading: this.isLoadingSharedData,
        },
        {
          icon: 'issues',
          link: `${this.webPath}/issues`,
          text: this.openIssuesText,
          isLoading: this.isLoadingDetails,
        },
        {
          icon: 'merge-request',
          link: `${this.webPath}/merge_requests`,
          text: this.openMergeRequestText,
          isLoading: this.isLoadingDetails,
        },
        {
          icon: 'clock',
          text: this.lastReleaseText,
          isLoading: this.isLoadingSharedData,
        },
      ];
    },
  },
  i18n: {
    title: s__('CiCatalog|About this project'),
    projectLink: s__('CiCatalog|Go to the project'),
    lastRelease: s__('CiCatalog|Last release at %{date}'),
    lastReleaseMissing: s__('CiCatalog|No release available'),
  },
};
</script>

<template>
  <div class="gl-mt-5 gl-ml-11">
    <div class="gl-font-lg gl-font-weight-bold gl-mb-2">{{ $options.i18n.title }}</div>
    <ul class="gl-list-style-none gl-p-0 gl-display-flex gl-flex-direction-column gl-gap-2">
      <li v-for="item in projectInfoItems" :key="`${item.icon}`" class="gl-display-flex">
        <gl-icon class="gl-text-primary gl-mr-3" :name="item.icon" />
        <gl-skeleton-loader v-if="item.isLoading" :lines="1" :width="160" />
        <template v-else>
          <gl-link v-if="item.link" :href="item.link"> {{ item.text }} </gl-link>
          <span v-else class="gl-text-secondary">
            {{ item.text }}
          </span>
        </template>
      </li>
    </ul>
  </div>
</template>
