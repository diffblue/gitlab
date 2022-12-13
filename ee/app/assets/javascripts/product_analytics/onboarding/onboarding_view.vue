<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'ProductAnalyticsOnboardingView',
  components: {
    GlEmptyState,
  },
  inject: {
    chartEmptyStateIllustrationPath: {
      type: String,
    },
  },
  i18n: {
    title: s__('Product Analytics|Analyze your product with Product Analytics'),
    description: s__(
      'Product Analytics|Set up Product Analytics to track how your product is performing. Combine it with your GitLab data to better understand where you can improve your product and development processes.',
    ),
    setUpBtnText: s__('Product Analytics|Set up product analytics...'),
    learnMoreBtnText: __('Learn more'),
  },
  docsPath: helpPagePath('user/product_analytics/index'),
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="chartEmptyStateIllustrationPath"
    :primary-button-text="$options.i18n.setUpBtnText"
    primary-button-link="#"
    :secondary-button-text="$options.i18n.learnMoreBtnText"
    :secondary-button-link="$options.docsPath"
  >
    <template #description>
      <p class="gl-max-w-80">
        {{ $options.i18n.description }}
      </p>
    </template>
  </gl-empty-state>
</template>
