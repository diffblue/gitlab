<script>
import { GlFormCheckboxTree } from '@gitlab/ui';
import { AUDIT_STREAMS_FILTERING } from '../../constants';

export default {
  components: {
    GlFormCheckboxTree,
  },
  props: {
    filterOptions: {
      type: Array,
      required: true,
    },
    filterSelected: {
      type: Array,
      required: true,
    },
  },
  computed: {
    options() {
      return this.filterOptions.map((value) => ({ value }));
    },
  },
  i18n: { ...AUDIT_STREAMS_FILTERING },
};
</script>

<template>
  <gl-form-checkbox-tree
    :options="options"
    :value="filterSelected"
    :select-all-label="$options.i18n.SELECT_ALL"
    :unselect-all-label="$options.i18n.UNSELECT_ALL"
    @change="$emit('updateFilters', $event)"
  />
</template>
