<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { mapState } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  name: 'GeoNodeCoreDetails',
  i18n: {
    url: __('URL'),
    internalUrl: s__('Geo|Internal URL'),
    gitlabVersion: __('GitLab version'),
    unknown: __('Unknown'),
  },
  components: {
    GlLink,
    GlIcon,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['primaryVersion', 'primaryRevision']),
    nodeVersion() {
      if (!this.node.version || !this.node.revision) {
        return this.$options.i18n.unknown;
      }
      return `${this.node.version} (${this.node.revision})`;
    },
    versionMismatch() {
      return (
        this.node.version !== this.primaryVersion || this.node.revision !== this.primaryRevision
      );
    },
  },
};
</script>

<template>
  <div class="gl-display-grid gl-lg-display-block! geo-node-core-details-grid-columns">
    <div class="gl-display-flex gl-flex-direction-column gl-lg-mb-5">
      <span>{{ $options.i18n.url }}</span>
      <gl-link
        class="gl-text-gray-900 gl-font-weight-bold gl-text-decoration-underline"
        :href="node.url"
        target="_blank"
        rel="noopener noreferrer"
      >
        {{ node.url }}
        <gl-icon name="external-link" class="gl-ml-1" />
      </gl-link>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-lg-my-5">
      <span>{{ $options.i18n.internalUrl }}</span>
      <span class="gl-font-weight-bold" data-testid="node-internal-url">{{
        node.internalUrl
      }}</span>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-lg-mt-5">
      <span>{{ $options.i18n.gitlabVersion }}</span>
      <span
        :class="{ 'gl-text-red-500': versionMismatch }"
        class="gl-font-weight-bold"
        data-testid="node-version"
      >
        {{ nodeVersion }}
      </span>
    </div>
  </div>
</template>
