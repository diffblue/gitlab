<script>
import {
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTruncate,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default {
  components: { GlIcon, GlLink, GlLoadingIcon, GlTruncate },
  directives: {
    GlTooltip,
  },
  inject: {
    endpoint: { default: '' },
  },
  data() {
    return {
      featureFlags: [],
      loading: true,
    };
  },
  i18n: {
    title: __('Related feature flags'),
    error: __('There was an error loading related feature flags'),
    active: __('Active'),
    inactive: __('Inactive'),
  },
  computed: {
    shouldShowRelatedFeatureFlags() {
      return this.loading || this.numberOfFeatureFlags > 0;
    },
    cardHeaderClass() {
      return { 'gl-border-b-0': this.numberOfFeatureFlags === 0 };
    },
    numberOfFeatureFlags() {
      return this.featureFlags?.length ?? 0;
    },
  },
  mounted() {
    if (this.endpoint) {
      axios
        .get(this.endpoint)
        .then(({ data }) => {
          this.featureFlags = data;
        })
        .catch((error) =>
          createFlash({
            message: this.$options.i18n.error,
            error,
          }),
        )
        .finally(() => {
          this.loading = false;
        });
    } else {
      this.loading = false;
    }
  },
  methods: {
    icon({ active }) {
      return active ? 'feature-flag' : 'feature-flag-disabled';
    },
    iconTooltip({ active }) {
      return active ? this.$options.i18n.active : this.$options.i18n.inactive;
    },
  },
};
</script>
<template>
  <div
    v-if="shouldShowRelatedFeatureFlags"
    id="related-feature-flags"
    class="card card-slim gl-overflow-hidden"
  >
    <div
      :class="cardHeaderClass"
      class="card-header gl-display-flex gl-justify-content-start gl-align-items-center"
    >
      <h3 class="card-title gl-my-0 gl-display-flex gl-align-items-center gl-w-full gl-relative h5">
        <gl-link
          id="user-content-related-feature-flags"
          class="anchor gl-text-decoration-none gl-absolute gl-mr-2"
          href="#related-feature-flags"
          aria-hidden="true"
        />
        {{ $options.i18n.title }}
        <gl-icon class="text-secondary gl-mr-2" name="feature-flag" />
        <span class="h5">{{ numberOfFeatureFlags }}</span>
      </h3>
    </div>
    <gl-loading-icon v-if="loading" size="sm" class="gl-my-3" />
    <ul v-else class="content-list related-items-list">
      <li
        v-for="flag in featureFlags"
        :key="flag.id"
        class="gl-display-flex"
        data-testid="feature-flag-details"
      >
        <gl-icon
          v-gl-tooltip
          :name="icon(flag)"
          :title="iconTooltip(flag)"
          class="gl-mr-3"
          data-testid="feature-flag-details-icon"
        />
        <gl-link
          v-gl-tooltip
          :title="flag.name"
          :href="flag.path"
          class="gl-str-truncated"
          data-testid="feature-flag-details-link"
        >
          <gl-truncate :text="flag.name" />
        </gl-link>
        <span
          v-gl-tooltip
          :title="flag.reference"
          class="text-secondary gl-mt-3 gl-lg-mt-0 gl-lg-ml-3 gl-white-space-nowrap"
          data-testid="feature-flag-details-reference"
        >
          <gl-truncate :text="flag.reference" />
        </span>
      </li>
    </ul>
  </div>
</template>
