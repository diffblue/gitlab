<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
  SPECIFIC_BRANCHES,
} from 'ee/security_orchestration/components/policy_editor/constants';
import { slugifyToArray } from '../../utils';

export default {
  i18n: {
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
  },
  name: 'BranchTypeSelector',
  components: {
    GlCollapsibleListbox,
    GlFormInput,
  },
  inject: ['namespaceType'],
  props: {
    branchesToAdd: {
      type: String,
      required: false,
      default: null,
    },
    branchTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedBranchType: {
      type: String,
      required: false,
      default: SPECIFIC_BRANCHES.value,
    },
  },
  computed: {
    defaultBranchTypeItems() {
      return this.branchTypes.length > 0
        ? this.branchTypes
        : SCAN_EXECUTION_BRANCH_TYPE_OPTIONS(this.namespaceType);
    },
    isBranchScope() {
      return this.selectedBranchType === SPECIFIC_BRANCHES.value;
    },
  },
  methods: {
    handleSelect(branchType) {
      this.$emit('set-branch-type', branchType);
    },
    handleInput(values) {
      const branches = slugifyToArray(values, ',');
      this.$emit('input', branches);
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-flex gl-gap-3">
    <gl-collapsible-listbox
      id="branch-type-selector"
      :items="defaultBranchTypeItems"
      :selected="selectedBranchType"
      @select="handleSelect"
    />

    <gl-form-input
      v-if="isBranchScope"
      :value="branchesToAdd"
      class="gl-max-w-34"
      size="lg"
      :placeholder="$options.i18n.selectedBranchesPlaceholder"
      data-testid="rule-branches"
      @input="handleInput"
    />
  </div>
</template>
