<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { convertToTitleCase } from '~/lib/utils/text_utility';

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: ['roleApproverTypes'],
  props: {
    existingApprovers: {
      type: Array,
      required: false,
      default: () => [],
    },
    state: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    hasValidRoles() {
      return this.existingApprovers.every((role) => this.roleApproverTypes.includes(role));
    },
    roles() {
      return this.roleApproverTypes.map((r) => ({ text: convertToTitleCase(r), value: r }));
    },
    toggleText() {
      return this.existingApprovers.length && this.hasValidRoles
        ? this.existingApprovers
            .map((r) => this.roles.find((roleValue) => roleValue.value === r).text)
            .join(', ')
        : s__('SecurityOrchestration|Choose specific role');
    },
  },
  watch: {
    hasValidRoles(value) {
      if (!value) {
        this.$emit('error');
      }
    },
  },
  methods: {
    handleSelectedRoles(selectedRoles) {
      this.$emit('updateSelectedApprovers', selectedRoles);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="roles"
    is-check-centered
    multiple
    :toggle-class="['gl-max-w-26', { 'gl-inset-border-1-red-500!': !state }]"
    :selected="existingApprovers"
    :toggle-text="toggleText"
    @select="handleSelectedRoles"
  />
</template>
