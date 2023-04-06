<script>
import {
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTruncate,
  GlCard,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default {
  components: { GlIcon, GlLink, GlLoadingIcon, GlTruncate, GlCard },
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
          createAlert({
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
  <gl-card
    v-if="shouldShowRelatedFeatureFlags"
    id="related-feature-flags"
    class="gl-overflow-hidden gl-mt-5 gl-mb-0 gl-bg-gray-10"
    header-class="card-header gl-line-height-24 gl-pl-5 gl-pr-4 gl-py-4 gl-bg-white"
    body-class="gl-p-0 gl-mx-5"
  >
    <template #header>
      <h3
        class="card-title h5 gl-my-0 gl-relative gl-display-flex gl-align-items-center gl-flex-grow-1 gl-line-height-24"
      >
        <gl-link
          id="user-content-related-feature-flags"
          class="anchor gl-text-decoration-none gl-absolute gl-mr-2"
          href="#related-feature-flags"
          aria-hidden="true"
        />
        {{ $options.i18n.title }}
        <gl-icon class="gl-text-gray-500 gl-ml-3 gl-mr-2" name="feature-flag" />
        <span class="gl-text-gray-500">{{ numberOfFeatureFlags }}</span>
      </h3>
    </template>
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
          class="gl-mr-2"
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
  </gl-card>
</template>
