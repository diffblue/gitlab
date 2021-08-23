<script>
import { GlFormCheckbox, GlIcon, GlPopover } from '@gitlab/ui';
import { slugify } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

export default {
  components: {
    GlFormCheckbox,
    GlIcon,
    GlPopover,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: Boolean,
      required: false,
      default: false,
    },
    locked: {
      type: Boolean,
      required: false,
      default: false,
    },
    lockedText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    lockIconId() {
      return `approval-settings-checkbox-lock-icon-${slugify(this.label)}`;
    },
  },
  methods: {
    input(value) {
      this.$emit('input', value);
    },
  },
  i18n: {
    lockIconTitle: __('Setting enforced'),
  },
};
</script>

<template>
  <gl-form-checkbox :disabled="locked" :checked="value" @input="input">
    {{ label }}
    <template v-if="locked">
      <gl-icon :id="lockIconId" data-testid="lock-icon" name="lock" />
      <gl-popover
        :target="lockIconId"
        container="viewport"
        placement="top"
        :title="$options.i18n.lockIconTitle"
        triggers="hover focus"
        :content="lockedText"
      />
    </template>
  </gl-form-checkbox>
</template>
