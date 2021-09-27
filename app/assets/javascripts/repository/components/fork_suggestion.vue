<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    message: __(
      'You can’t edit files directly in this project. Fork this project and submit a merge request with your changes.',
    ),
    fork: __('Fork'),
    cancel: __('Cancel'),
  },
  components: {
    GlButton,
  },
  props: {
    forkPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="file-fork-suggestion">
    <span class="file-fork-suggestion-note" data-testid="message">{{ $options.i18n.message }}</span>

    <gl-button
      class="gl-mr-3"
      category="secondary"
      variant="confirm"
      :href="forkPath"
      data-testid="fork"
    >
      {{ $options.i18n.fork }}
    </gl-button>

    <gl-button class="gl-mr-3" data-testid="cancel" @click="$emit('cancel')">
      {{ $options.i18n.cancel }}
    </gl-button>
  </div>
</template>
