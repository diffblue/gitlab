<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  name: 'GeoSiteCoreDetails',
  i18n: {
    url: s__('Geo|External URL'),
    internalUrl: s__('Geo|Internal URL'),
    gitlabVersion: __('GitLab version'),
    unknown: __('Unknown'),
  },
  components: {
    GlLink,
    GlIcon,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['siteHasVersionMismatch']),
    siteVersion() {
      if (!this.site.version || !this.site.revision) {
        return this.$options.i18n.unknown;
      }
      return `${this.site.version} (${this.site.revision})`;
    },
    hasMismatchVersion() {
      return this.siteHasVersionMismatch(this.site.id);
    },
  },
};
</script>

<template>
  <div class="gl-display-grid gl-lg-display-block! geo-site-core-details-grid-columns">
    <div class="gl-display-flex gl-flex-direction-column gl-lg-mb-5">
      <span>{{ $options.i18n.url }}</span>
      <gl-link
        class="gl-text-gray-900 gl-font-weight-bold gl-text-decoration-underline"
        :href="site.url"
        target="_blank"
        rel="noopener noreferrer"
      >
        {{ site.url }}
        <gl-icon name="external-link" class="gl-ml-1" />
      </gl-link>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-lg-my-5">
      <span>{{ $options.i18n.internalUrl }}</span>
      <span class="gl-font-weight-bold" data-testid="site-internal-url">{{
        site.internalUrl
      }}</span>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-lg-mt-5">
      <span>{{ $options.i18n.gitlabVersion }}</span>
      <span
        :class="{ 'gl-text-red-500': hasMismatchVersion }"
        class="gl-font-weight-bold"
        data-testid="site-version"
      >
        {{ siteVersion }}
      </span>
    </div>
  </div>
</template>
