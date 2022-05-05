<script>
import { s__ } from '~/locale';

export default {
  i18n: {
    defaultEmptyStateHeader: s__('DastProfiles|Scanner Profile'),
    defaultHeader: s__('DastProfiles|Scanner profile'),
    defaultContent: s__('DastProfiles|No scanner profile selected.'),
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-4">
      <h4 class="gl-font-lg gl-mt-0 gl-mb-2">
        <slot name="main-header">
          {{ $options.i18n.defaultEmptyStateHeader }}
        </slot>
      </h4>
      <slot name="header-description"></slot>
    </div>
    <div
      class="gl-bg-gray-10 gl-display-flex gl-flex-direction-column gl-text-center gl-align-items-center gl-p-6 gl-rounded-small gl-mb-5"
    >
      <h5 class="gl-h5 gl-text-gray-500 gl-mt-0 gl-mb-2">
        <slot name="header">{{ $options.i18n.defaultHeader }}</slot>
      </h5>
      <span class="gl-text-gray-500">
        <slot name="content">{{ $options.i18n.defaultContent }}</slot>
      </span>
    </div>
  </div>
</template>
