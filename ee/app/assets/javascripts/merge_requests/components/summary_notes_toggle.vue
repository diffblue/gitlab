<script>
import { GlDisclosureDropdownItem, GlIcon } from '@gitlab/ui';
import { summaryState } from './summary_notes.vue';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlIcon,
  },
  methods: {
    toggleOpen() {
      summaryState.toggleOpen();

      this.$emit('action');
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item @action="toggleOpen">
    <template #list-item>
      {{ __('View summary notes') }}
      <gl-icon name="tanuki-ai" class="gl-text-purple-600 gl-float-right" />
    </template>
  </gl-disclosure-dropdown-item>
</template>
