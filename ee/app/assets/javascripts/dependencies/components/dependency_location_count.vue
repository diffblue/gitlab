<script>
import { GlIcon, GlTruncate } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'DependencyLocationCount',
  components: {
    GlIcon,
    GlTruncate,
  },
  props: {
    locationCount: {
      type: Number,
      required: true,
    },
  },
  computed: {
    locationText() {
      return sprintf(s__('Dependencies|%{locationCount} locations'), {
        locationCount: Number.isNaN(this.locationCount) ? 0 : this.locationCount,
      });
    },
  },
};
</script>

<template>
  <span class="gl-md-white-space-nowrap">
    <gl-icon name="doc-text" />
    <gl-truncate
      class="gl-display-none gl-md-display-inline-flex"
      position="start"
      :text="locationText"
      with-tooltip
    />
  </span>
</template>
