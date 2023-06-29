<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import ProtectedBranchesDropdown from 'ee/security_orchestration/components/protected_branches_dropdown.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { ALL_PROTECTED_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';
import { slugifyToArray } from '../utils';
import { SPECIFIC_BRANCHES } from '../constants';

const BRANCHES_OPTIONS = [
  { ...ALL_PROTECTED_BRANCHES, text: ALL_PROTECTED_BRANCHES.name },
  SPECIFIC_BRANCHES,
];

export default {
  components: {
    GlCollapsibleListbox,
    GlFormInput,
    ProtectedBranchesDropdown,
  },
  inject: ['namespaceId', 'namespaceType'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    groupLevelBranchInput: s__('SecurityOrchestration|group level branch input'),
    groupLevelBranchSelector: s__('SecurityOrchestration|group level branch selector'),
  },
  data() {
    return {
      showProtectedBranchesError: false,
      selected: !this.initRule.branches?.join()
        ? ALL_PROTECTED_BRANCHES.value
        : SPECIFIC_BRANCHES.value,
    };
  },
  computed: {
    branchesText() {
      return n__('branch', 'branches', this.branchesToAdd.length);
    },
    enteredBranches: {
      get() {
        return this.initRule.branches?.join() || '';
      },
      set(value) {
        const branches = slugifyToArray(value).filter((branch) => branch !== '*');
        this.triggerChanged({ branches });
      },
    },
    showBranchesLabel() {
      if (!Array.isArray(this.initRule.branches)) {
        return false;
      }

      return Boolean(this.initRule.branches?.length) || this.showInput;
    },
    branchesToAdd: {
      get() {
        return this.initRule.branches;
      },
      set(values) {
        this.triggerChanged({ branches: values || null });
      },
    },
    displayBranchSelector() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    showInput() {
      return this.selected === SPECIFIC_BRANCHES.value;
    },
  },
  methods: {
    handleSelect(value) {
      this.selected = value;
      if (value === ALL_PROTECTED_BRANCHES.value) {
        this.branchesToAdd = [];
      }
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    handleError({ hasErrored, error }) {
      this.showProtectedBranchesError = hasErrored;
      this.$emit('error', error);
    },
  },
  BRANCHES_OPTIONS,
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <label for="group-level-branch-selector" class="gl-sr-only">
      {{ $options.i18n.groupLevelBranchSelector }}
    </label>
    <gl-collapsible-listbox
      id="group-level-branch-selector"
      :items="$options.BRANCHES_OPTIONS"
      :selected="selected"
      @select="handleSelect"
    />

    <template v-if="displayBranchSelector">
      <protected-branches-dropdown
        v-if="showInput"
        v-model="branchesToAdd"
        class="gl-max-w-26"
        :has-error="showProtectedBranchesError"
        :selected="branchesToAdd"
        :select-all-empty="true"
        :project-id="namespaceId"
        @error="handleError"
      />
    </template>
    <template v-else>
      <span v-if="showInput" class="gl-display-flex">
        <label for="group-level-branch-input" class="gl-sr-only">
          {{ $options.i18n.groupLevelBranchInput }}
        </label>
        <gl-form-input
          id="group-level-branch-input"
          v-model="enteredBranches"
          class="gl-display-inline gl-w-30 gl-ml-3"
          type="text"
        />
      </span>
    </template>
    <span v-if="showBranchesLabel" data-testid="branches-label">{{ branchesText }}</span>
  </div>
</template>
