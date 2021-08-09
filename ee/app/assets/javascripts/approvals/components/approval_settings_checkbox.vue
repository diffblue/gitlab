<script>
import { GlFormCheckbox, GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { slugify } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import { APPROVALS_HELP_PATH } from '../constants';

export default {
  components: {
    GlFormCheckbox,
    GlIcon,
    GlLink,
    GlPopover,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    anchor: {
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
    href() {
      return helpPagePath(APPROVALS_HELP_PATH, { anchor: this.anchor });
    },
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
    helpLinkText: __('Learn more.'),
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
    <gl-link :href="href" target="_blank">
      {{ $options.i18n.helpLinkText }}
    </gl-link>
  </gl-form-checkbox>
</template>
