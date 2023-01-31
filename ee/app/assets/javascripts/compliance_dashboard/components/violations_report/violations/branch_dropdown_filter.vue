<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import { BRANCH_FILTER_OPTIONS } from '../../../constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    defaultBranch: {
      type: String,
      default: '',
      required: false,
    },
  },
  data() {
    return {
      selectedBranch: this.defaultBranch || BRANCH_FILTER_OPTIONS.allBranches,
    };
  },
  methods: {
    isSelectedBranch(branch) {
      return branch.toUpperCase() === this.selectedBranch.toUpperCase();
    },
    selectBranch(branch) {
      this.selectedBranch = branch;
      this.$emit('selected', this.selectedBranch);
    },
  },
  filterOptions: BRANCH_FILTER_OPTIONS,
  i18n: {
    filterHeader: __('Select branches'),
  },
};
</script>

<template>
  <gl-dropdown :header-text="$options.i18n.filterHeader" :text="selectedBranch" block>
    <gl-dropdown-item
      v-for="(branchOption, key) in $options.filterOptions"
      :key="key"
      :is-checked="isSelectedBranch(branchOption)"
      is-check-item
      @click="selectBranch(branchOption)"
      >{{ branchOption }}</gl-dropdown-item
    >
  </gl-dropdown>
</template>
