<script>
import { uniqueId } from 'lodash';
import { GlIcon, GlPopover } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlPopover,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    lockedText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    lockIconId() {
      return uniqueId('approval-settings-lock-icon-');
    },
  },
  i18n: {
    lockIconTitle: __('Setting enforced'),
  },
};
</script>

<template>
  <span>
    <gl-icon :id="lockIconId" data-testid="lock-icon" name="lock" />
    <gl-popover
      :target="lockIconId"
      container="viewport"
      placement="top"
      :title="$options.i18n.lockIconTitle"
      triggers="hover focus"
      :content="lockedText"
    />
  </span>
</template>
