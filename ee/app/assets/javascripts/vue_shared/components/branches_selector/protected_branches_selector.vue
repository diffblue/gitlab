<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { BRANCH_FETCH_DELAY, ALL_BRANCHES, ALL_PROTECTED_BRANCHES, PLACEHOLDER } from './constants';

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    selectedBranches: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedBranchesNames: {
      type: Array,
      required: false,
      default: () => [],
    },
    isInvalid: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowAllBranchesOption: {
      type: Boolean,
      required: false,
      default: true,
    },
    allowAllProtectedBranchesOption: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      branches: [],
      initialLoading: false,
      searching: false,
      selected: null,
    };
  },
  computed: {
    branchesValues() {
      return this.branches.map((b) => ({ ...b, value: b.name }));
    },
    selectedBranch() {
      const idsOnly = this.selectedBranches.map((branch) => branch.id);
      const selectedById = this.branches.find((branch) => idsOnly.includes(branch.id));
      const selectedByName = this.branches.find((branch) =>
        this.selectedBranchesNames.includes(branch.name),
      );

      if (this.allowAllBranchesOption && idsOnly.includes(ALL_BRANCHES.id)) {
        return ALL_BRANCHES;
      } else if (
        this.allowAllProtectedBranchesOption &&
        idsOnly.includes(ALL_PROTECTED_BRANCHES.id)
      ) {
        return ALL_PROTECTED_BRANCHES;
      }

      const userSelectedBranch = selectedById || selectedByName || this.selected;

      if (userSelectedBranch) {
        return userSelectedBranch;
      } else if (this.allowAllBranchesOption) {
        return ALL_BRANCHES;
      } else if (this.allowAllProtectedBranchesOption) {
        return ALL_PROTECTED_BRANCHES;
      }

      return PLACEHOLDER;
    },
    selectedBranchValue() {
      return this.selectedBranch.name;
    },
  },
  created() {
    this.handleSearch = debounce(this.fetchBranches, BRANCH_FETCH_DELAY);
  },
  destroyed() {
    this.handleSearch.cancel();
  },
  mounted() {
    this.initialLoading = true;
    this.fetchBranches()
      // Errors are handled by fetchBranches
      .catch(() => {})
      .finally(() => {
        this.initialLoading = false;
      });
  },
  methods: {
    fetchBranches(term) {
      this.searching = true;
      const includeAllBranches = !term || term.toLowerCase().includes('all');

      const baseBranches = [];

      if (includeAllBranches) {
        if (this.allowAllBranchesOption) {
          baseBranches.push(ALL_BRANCHES);
        }

        if (this.allowAllProtectedBranchesOption) {
          baseBranches.push(ALL_PROTECTED_BRANCHES);
        }
      }

      return Api.projectProtectedBranches(this.projectId, term)
        .then((branches) => {
          this.$emit('apiError', { hasErrored: false });
          this.branches = [...baseBranches, ...branches];
        })
        .catch((error) => {
          this.$emit('apiError', { hasErrored: true, error });
          this.branches = baseBranches;
        })
        .finally(() => {
          this.searching = false;
        });
    },
    handleSelect(value) {
      const newlySelectedBranch = this.branchesValues.find((b) => b.value === value);
      this.onSelect(newlySelectedBranch);
    },
    onSelect(branch) {
      this.selected = branch;
      this.$emit('input', branch);
    },
    branchNameClass(id) {
      return {
        monospace: id !== null,
      };
    },
  },
  i18n: {
    header: __('Select branch'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="branchesValues"
    block
    :class="{ 'is-invalid': isInvalid }"
    :toggle-text="selectedBranch.name"
    :loading="initialLoading"
    :header-text="$options.i18n.header"
    searchable
    :searching="searching"
    :selected="selectedBranchValue"
    @search="handleSearch"
    @select="handleSelect"
  >
    <template #list-item="{ item }">
      <span :class="branchNameClass(item.id)">{{ item.name }}</span>
    </template>
  </gl-collapsible-listbox>
</template>
