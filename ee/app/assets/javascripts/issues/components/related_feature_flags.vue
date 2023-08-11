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
    class="gl-new-card gl-overflow-hidden"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-mx-3"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title">
          <gl-link
            id="user-content-related-feature-flags"
            class="anchor gl-text-decoration-none gl-absolute gl-mr-2"
            href="#related-feature-flags"
            aria-hidden="true"
          />
          {{ $options.i18n.title }}
        </h3>
        <div data-testid="feature-flag-number" class="gl-new-card-count">
          <gl-icon class="gl-mr-2" name="feature-flag" />
          <span>{{ numberOfFeatureFlags }}</span>
        </div>
      </div>
    </template>
    <gl-loading-icon v-if="loading" size="sm" class="gl-my-4" />
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
        <gl-link v-gl-tooltip :title="flag.name" :href="flag.path" class="gl-str-truncated">
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
