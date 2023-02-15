<script>
import { GlLink } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  name: 'ReportHeader',
  components: {
    GlLink,
  },
  props: {
    heading: {
      type: String,
      required: true,
    },
    subheading: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    learnMore: __('Learn more.'),
  },
};
</script>
<template>
  <header
    class="gl-mt-5 gl-mb-6 gl-display-flex gl-sm-flex-direction-column gl-justify-content-space-between"
  >
    <div>
      <h2 class="gl-flex-grow-1 gl-my-0" data-testid="heading">{{ heading }}</h2>
      <p class="gl-mt-5" data-testid="subheading">
        {{ subheading }}
        <gl-link :href="documentationPath">{{ $options.i18n.learnMore }}</gl-link>
      </p>
    </div>
    <div>
      <slot name="actions"></slot>
    </div>
  </header>
</template>
