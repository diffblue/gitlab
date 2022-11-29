<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { BRANCH_FETCH_DELAY, ALL_BRANCHES, ALL_PROTECTED_BRANCHES, PLACEHOLDER } from './constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
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
      searchTerm: '',
      selected: null,
    };
  },
  computed: {
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
    search: debounce(function debouncedSearch() {
      this.fetchBranches(this.searchTerm);
    }, BRANCH_FETCH_DELAY),
    isSelectedBranch(id) {
      return this.selectedBranch.id === id;
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
  <gl-dropdown
    :class="{ 'is-invalid': isInvalid }"
    class="gl-w-full gl-dropdown-menu-full-width"
    :text="selectedBranch.name"
    :loading="initialLoading"
    :header-text="$options.i18n.header"
  >
    <template #header>
      <gl-search-box-by-type v-model="searchTerm" :is-loading="searching" @input="search" />
    </template>
    <gl-dropdown-item
      v-for="branch in branches"
      :key="branch.id"
      is-check-item
      :is-checked="isSelectedBranch(branch.id)"
      @click="onSelect(branch)"
    >
      <span :class="branchNameClass(branch.id)">{{ branch.name }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
