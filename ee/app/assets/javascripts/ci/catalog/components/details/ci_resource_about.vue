<script>
import { n__, s__, sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  props: {
    statistics: {
      required: true,
      type: Object,
    },
    versions: {
      required: true,
      type: Array,
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
    openedIssuesText() {
      return n__('%d opened Issue', '%d opened Issues', this.statistics.issues);
    },
    openedMergeRequestText() {
      return n__(
        '%d opened Merge Request',
        '%d opened Merge Requests',
        this.statistics.mergeRequests,
      );
    },
    releasedAt() {
      return this.hasVersion && formatDate(this.versions[0].releasedAt, 'yyyy-mm-dd');
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
  <div>
    <h3>{{ $options.i18n.title }}</h3>
    <ul class="gl-list-style-none">
      <li>{{ $options.i18n.projectLink }}</li>
      <li>{{ openedIssuesText }}</li>
      <li>{{ openedMergeRequestText }}</li>
      <li>{{ lastReleaseText }}</li>
    </ul>
  </div>
</template>
