<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';
import { ADD_STREAM, AUDIT_STREAMS_EMPTY_STATE_I18N } from '../../constants';

export default {
  components: {
    GlButton,
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath'],
  i18n: {
    ...AUDIT_STREAMS_EMPTY_STATE_I18N,
    ADD_STREAM,
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.TITLE"
    :svg-path="emptyStateSvgPath"
    :svg-height="72"
    class="gl-mt-5"
  >
    <template #title>
      <h3 class="h4 gl-font-size-h-display gl-line-height-36 gl-mt-n3">
        {{ $options.i18n.TITLE }}
      </h3>
    </template>
    <template #description>
      <p>{{ $options.i18n.DESCRIPTION_1 }}</p>
      <p>{{ $options.i18n.DESCRIPTION_2 }}</p>
    </template>
    <template #actions>
      <gl-button variant="confirm" @click="$emit('add')">
        {{ $options.i18n.ADD_STREAM }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
