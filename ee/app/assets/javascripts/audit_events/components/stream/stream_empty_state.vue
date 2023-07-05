<script>
import { GlEmptyState, GlDisclosureDropdown } from '@gitlab/ui';
import {
  ADD_STREAM,
  AUDIT_STREAMS_EMPTY_STATE_I18N,
  ADD_HTTP,
  ADD_GCP_LOGGING,
  DESTINATION_TYPE_HTTP,
  DESTINATION_TYPE_GCP_LOGGING,
} from '../../constants';

export default {
  components: {
    GlEmptyState,
    GlDisclosureDropdown,
  },
  inject: ['groupPath', 'emptyStateSvgPath'],
  computed: {
    isInstance() {
      return this.groupPath === 'instance';
    },
    destinationOptions() {
      return [
        {
          text: ADD_HTTP,
          action: () => {
            this.$emit('add', DESTINATION_TYPE_HTTP);
          },
        },
        {
          text: ADD_GCP_LOGGING,
          action: () => {
            this.$emit('add', DESTINATION_TYPE_GCP_LOGGING);
          },
        },
      ];
    },
    addOptions() {
      return this.isInstance ? [this.destinationOptions[0]] : this.destinationOptions;
    },
  },
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
      <gl-disclosure-dropdown
        :toggle-text="$options.i18n.ADD_STREAM"
        category="primary"
        variant="confirm"
        data-testid="dropdown-toggle"
        :items="addOptions"
      />
    </template>
  </gl-empty-state>
</template>
