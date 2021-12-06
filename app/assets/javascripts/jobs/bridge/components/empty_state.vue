<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'BridgeEmptyState',
  i18n: {
    title: __('This job triggers a downstream pipeline'),
    linkBtnText: __('View downstream pipeline'),
  },
  components: {
    GlButton,
  },
  inject: {
    downstreamPipelinePath: {
      type: String,
      default: '#',
    },
    emptyStateIllustrationPath: {
      type: String,
      require: true,
    },
  },
};
</script>

<template>
  <!-- TODO: add downstream pipeline path -->
  <div class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-mt-11">
    <img :src="emptyStateIllustrationPath" />
    <h1 class="gl-font-size-h1 center">{{ $options.i18n.title }}</h1>
    <gl-button class="gl-mt-3" size="medium" :href="downstreamPipelinePath">
      {{ $options.i18n.linkBtnText }}
    </gl-button>
  </div>
</template>
