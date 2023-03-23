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
  },
  data() {
    return {
      selectedRoles: this.existingApprovers,
    };
  },
  computed: {
    roles() {
      return this.roleApproverTypes.map((r) => ({ text: convertToTitleCase(r), value: r }));
    },
    toggleText() {
      return this.selectedRoles.length
        ? this.selectedRoles
            .map((r) => this.roles.find((roleValue) => roleValue.value === r).text)
            .join(', ')
        : s__('SecurityOrchestration|Choose specific role');
    },
  },
  methods: {
    handleSelectedRoles(selectedRoles) {
      this.selectedRoles = selectedRoles;

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
    toggle-class="gl-max-w-26"
    :selected="selectedRoles"
    :toggle-text="toggleText"
    @select="handleSelectedRoles"
  />
</template>
