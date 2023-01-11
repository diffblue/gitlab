<script>
import { GlButton, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { EMPTY_STATE_I18N } from '../constants';

export default {
  name: 'AnalyticsEmptyState',
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
  },
  inject: {
    chartEmptyStateIllustrationPath: {
      type: String,
    },
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return this.loading ? EMPTY_STATE_I18N.loading.title : EMPTY_STATE_I18N.empty.title;
    },
    description() {
      return this.loading
        ? EMPTY_STATE_I18N.loading.description
        : EMPTY_STATE_I18N.empty.description;
    },
  },
  i18n: EMPTY_STATE_I18N,
  docsPath: helpPagePath('user/product_analytics/index'),
};
</script>

<template>
  <gl-empty-state :title="title" :svg-path="chartEmptyStateIllustrationPath">
    <template #description>
      <p class="gl-max-w-80">
        {{ description }}
      </p>
    </template>
    <template #actions>
      <template v-if="!loading">
        <gl-button variant="confirm" data-testid="setup-btn" @click="$emit('initialize')">
          {{ $options.i18n.empty.setUpBtnText }}
        </gl-button>
        <gl-button :href="$options.docsPath" data-testid="learn-more-btn">
          {{ $options.i18n.empty.learnMoreBtnText }}
        </gl-button>
      </template>
      <gl-loading-icon v-else size="lg" class="gl-mt-5" />
    </template>
  </gl-empty-state>
</template>
