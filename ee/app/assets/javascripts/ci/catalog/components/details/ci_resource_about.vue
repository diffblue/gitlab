<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { n__, s__, sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    openIssuesCount: {
      required: true,
      type: Number,
    },
    openMergeRequestsCount: {
      required: true,
      type: Number,
    },
    versions: {
      required: true,
      type: Array,
    },
    webPath: {
      required: true,
      type: String,
    },
  },
  computed: {
    hasVersion() {
      return this.versions.length > 0;
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
      return this.hasVersion && formatDate(this.versions[0].releasedAt, 'yyyy-mm-dd');
    },
    statsConfig() {
      return [
        {
          icon: 'project',
          link: `${this.webPath}`,
          text: this.$options.i18n.projectLink,
        },
        {
          icon: 'issues',
          link: `${this.webPath}/issues`,
          text: this.openIssuesText,
        },
        {
          icon: 'merge-request',
          link: `${this.webPath}/merge_requests`,
          text: this.openMergeRequestText,
        },
        {
          icon: 'clock',
          text: this.lastReleaseText,
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
      <li v-for="stat in statsConfig" :key="`${stat.icon}`">
        <gl-icon class="gl-text-primary" :name="stat.icon" />
        <gl-link v-if="stat.link" :href="stat.link" class="gl-ml-3"> {{ stat.text }} </gl-link>
        <span v-else class="gl-ml-3 gl-text-secondary">
          {{ stat.text }}
        </span>
      </li>
    </ul>
  </div>
</template>
