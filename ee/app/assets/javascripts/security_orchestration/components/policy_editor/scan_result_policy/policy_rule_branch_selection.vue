<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { ALL_PROTECTED_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';
import { slugifyToArray } from '../utils';
import { SPECIFIC_BRANCHES } from '../constants';

const GROUP_LEVEL_BRANCHES_OPTIONS = [
  { ...ALL_PROTECTED_BRANCHES, text: ALL_PROTECTED_BRANCHES.name },
  SPECIFIC_BRANCHES,
];

export default {
  components: {
    GlCollapsibleListbox,
    GlFormInput,
    ProtectedBranchesSelector,
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
      return Boolean(this.initRule.branches?.length) || this.showInput;
    },
    branchesToAdd: {
      get() {
        return this.initRule.branches || [];
      },
      set(value) {
        const branches = value.id === ALL_PROTECTED_BRANCHES.id ? [] : [value.name];
        this.triggerChanged({ branches });
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
        this.branchesToAdd = ALL_PROTECTED_BRANCHES;
      }
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
  GROUP_LEVEL_BRANCHES_OPTIONS,
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <protected-branches-selector
      v-if="displayBranchSelector"
      v-model="branchesToAdd"
      class="gl-display-inline gl-max-w-26"
      :allow-all-branches-option="false"
      :allow-all-protected-branches-option="true"
      :project-id="namespaceId"
      :selected-branches-names="branchesToAdd"
    />
    <template v-else>
      <span class="gl-display-flex">
        <label for="group-level-branch-selector" class="gl-sr-only">
          {{ $options.i18n.groupLevelBranchSelector }}
        </label>
        <gl-collapsible-listbox
          id="group-level-branch-selector"
          :items="$options.GROUP_LEVEL_BRANCHES_OPTIONS"
          :selected="selected"
          @select="handleSelect"
        />
        <label for="group-level-branch-input" class="gl-sr-only">
          {{ $options.i18n.groupLevelBranchInput }}
        </label>
        <gl-form-input
          v-if="showInput"
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
