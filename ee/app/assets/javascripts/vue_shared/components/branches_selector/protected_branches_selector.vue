<script>
import { GlCollapsibleListbox, GlDropdownDivider, GlDropdownItem } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { BRANCH_FETCH_DELAY, ALL_BRANCHES, ALL_PROTECTED_BRANCHES, PLACEHOLDER } from './constants';

const createBranchObject = (value) => ({
  id: value,
  name: value,
  value,
});

export default {
  components: {
    GlCollapsibleListbox,
    GlDropdownDivider,
    GlDropdownItem,
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
    multiple: {
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
    };
  },
  computed: {
    branchesItems() {
      return this.branches.map((b) => ({ ...b, value: b.name }));
    },
    selectedBranch() {
      let selected = PLACEHOLDER;
      const allBranches = [...this.branches, ALL_BRANCHES, ALL_PROTECTED_BRANCHES];

      if (this.selectedBranches === null || this.selectedBranchesNames === null) {
        // If no branch is selected, then keep the selected as PLACEHOLDER
      } else if (this.selectedBranches?.length) {
        // Get user selected branches from this.selectedBranches
        const idsOnly = this.selectedBranches.map((branch) => branch.id);
        if (this.multiple) {
          selected = this.selectedBranches.map((selectedBranch) => {
            return allBranches.find((branch) => branch.id === selectedBranch.id) || selectedBranch;
          });
        } else {
          selected = allBranches.find((branch) => idsOnly.includes(branch.id));
        }
      } else if (this.selectedBranchesNames?.length) {
        // Get user selected branches from this.selectedBranchesNames
        if (this.multiple) {
          selected = this.selectedBranchesNames.map((name) => {
            return allBranches.find((branch) => branch.name === name) || createBranchObject(name);
          });
        } else {
          selected =
            allBranches.find((branch) => this.selectedBranchesNames.includes(branch.name)) ||
            createBranchObject(this.selectedBranchesNames[0]);
        }
      } else if (this.allowAllBranchesOption) {
        // Use default branches
        selected = ALL_BRANCHES;
      } else if (this.allowAllProtectedBranchesOption) {
        // Use default branches
        selected = ALL_PROTECTED_BRANCHES;
      }

      if (this.multiple && !Array.isArray(selected)) {
        return selected ? [selected] : [];
      }

      return selected;
    },
    selectedBranchName() {
      if (this.multiple) {
        return this.selectedBranch.map((u) => u.name);
      }

      // Retrieved branches do not have a value property
      return this.selectedBranch?.name;
    },
    toggleText() {
      if (this.multiple) {
        return this.selectedBranchName.join(', ') || PLACEHOLDER.name;
      }

      return this.selectedBranchName || PLACEHOLDER.name;
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

      return Api.projectProtectedBranches(this.projectId, term)
        .then((branches) => {
          this.$emit('apiError', { hasErrored: false });
          this.branches = branches;
        })
        .catch((error) => {
          this.$emit('apiError', { hasErrored: true, error });
          this.branches = [];
        })
        .finally(() => {
          this.searching = false;
        });
    },
    handleFooterClick(value) {
      let newlySelectedBranch;
      const currentBranchValue = this.multiple
        ? this.selectedBranch[0].value
        : this.selectedBranch.value;

      // If clicking on the same action as currently assigned, deselect it
      if (currentBranchValue === value) {
        this.onSelect(null);
      } else {
        switch (value) {
          case ALL_BRANCHES.value:
            newlySelectedBranch = ALL_BRANCHES;
            break;
          case ALL_PROTECTED_BRANCHES.value:
          default:
            newlySelectedBranch = ALL_PROTECTED_BRANCHES;
        }

        this.onSelect(this.multiple ? [newlySelectedBranch] : newlySelectedBranch);
      }
      this.$refs.branches.close();
    },
    handleSelect(name) {
      let newlySelectedBranch;

      if (this.multiple) {
        newlySelectedBranch = name.reduce((acc, selectedBranch) => {
          if (
            selectedBranch === ALL_BRANCHES.name ||
            selectedBranch === ALL_PROTECTED_BRANCHES.name
          ) {
            return acc;
          }

          return [...acc, this.branchesItems.find((b) => b.value === selectedBranch)];
        }, []);
      } else {
        newlySelectedBranch = this.branchesItems.find((b) => b.name === name);
      }

      this.onSelect(newlySelectedBranch);
    },
    isSelected(name) {
      if (this.multiple) {
        return Boolean(this.selectedBranchName.find((v) => v === name));
      }

      return this.selectedBranchName === name;
    },
    onSelect(branch) {
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
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
};
</script>

<template>
  <gl-collapsible-listbox
    ref="branches"
    :items="branchesItems"
    block
    :class="{ 'is-invalid': isInvalid }"
    :toggle-text="toggleText"
    :loading="initialLoading"
    :header-text="$options.i18n.header"
    :multiple="multiple"
    searchable
    :searching="searching"
    :selected="selectedBranchName"
    @search="handleSearch"
    @select="handleSelect"
  >
    <template #list-item="{ item }">
      <span :class="branchNameClass(item.id)">{{ item.name }}</span>
    </template>
    <template #footer>
      <gl-dropdown-divider v-if="allowAllBranchesOption || allowAllProtectedBranchesOption" />
      <gl-dropdown-item
        v-if="allowAllBranchesOption"
        data-testid="all-branches-option"
        class="gl-list-style-none"
        :is-check-item="true"
        :is-checked="isSelected($options.ALL_BRANCHES.name)"
        @click="handleFooterClick($options.ALL_BRANCHES.name)"
      >
        {{ $options.ALL_BRANCHES.name }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="allowAllProtectedBranchesOption"
        data-testid="all-protected-branches-option"
        class="gl-list-style-none"
        :is-check-item="true"
        :is-checked="isSelected($options.ALL_PROTECTED_BRANCHES.name)"
        @click="handleFooterClick($options.ALL_PROTECTED_BRANCHES.name)"
      >
        {{ $options.ALL_PROTECTED_BRANCHES.name }}
      </gl-dropdown-item>
    </template>
  </gl-collapsible-listbox>
</template>
