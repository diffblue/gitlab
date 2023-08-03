<script>
import { GlToggle, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/seats/constants';

export default {
  name: 'CodeSuggestionsAddonAssignment',
  i18n: {
    toggleLabel: __('Code Suggestions add-on status'),
    addonUnavailableTooltipText: __('The Code Suggestions add-on is not available.'),
  },
  components: {
    GlToggle,
    GlTooltip,
  },
  props: {
    userId: {
      type: Number,
      required: true,
    },
    addOns: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      toggleId: `toggle-${this.userId}`,
    };
  },
  computed: {
    isAssigned() {
      return Boolean(
        this.addOns?.assigned?.find((assigned) => assigned.name === ADD_ON_CODE_SUGGESTIONS),
      );
    },
    isAssignable() {
      return Boolean(
        this.addOns?.assignable?.find((assignable) => assignable.name === ADD_ON_CODE_SUGGESTIONS),
      );
    },
  },
};
</script>
<template>
  <div>
    <gl-toggle
      :id="toggleId"
      :value="isAssigned"
      :label="$options.i18n.toggleLabel"
      :disabled="!isAssignable"
      label-position="hidden"
    />
    <gl-tooltip v-if="!isAssignable" :target="toggleId">
      {{ $options.i18n.addonUnavailableTooltipText }}
    </gl-tooltip>
  </div>
</template>
