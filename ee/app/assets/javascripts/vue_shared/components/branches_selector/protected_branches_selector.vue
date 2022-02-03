<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { BRANCH_FETCH_DELAY, ALL_BRANCHES } from './constants';

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

      return selectedById || selectedByName || this.selected || ALL_BRANCHES;
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
      const excludeAllBranches = term && !term.toLowerCase().includes('all');

      return Api.projectProtectedBranches(this.projectId, term)
        .then((branches) => {
          this.$emit('apiError', { hasErrored: false });
          this.branches = excludeAllBranches ? branches : [ALL_BRANCHES, ...branches];
        })
        .catch((error) => {
          this.$emit('apiError', { hasErrored: true, error });
          this.branches = excludeAllBranches ? [] : [ALL_BRANCHES];
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
      :is-check-item="true"
      :is-checked="isSelectedBranch(branch.id)"
      @click="onSelect(branch)"
    >
      <span :class="branchNameClass(branch.id)">{{ branch.name }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
