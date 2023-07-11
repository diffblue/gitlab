<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export default {
  name: 'ProtectedBranchesDropdown',
  i18n: {
    errorMessage: __(
      'Could not retrieve the list of protected branches. Use the YAML editor mode, or refresh this page later. To view the list of protected branches, go to %{boldStart}Settings - Branches%{boldEnd} and expand %{boldStart}Protected branches%{boldEnd}.',
    ),
    headerTextMultiple: __('Select protected branches'),
    headerTextSingle: __('Choose protected branch'),
    selectAllLabel: __('Select all'),
    resetLabel: __('Clear all'),
    defaultToggleText: __('Select protected branch'),
    defaultToggleTextMultiple: __('Select protected branches'),
  },
  components: {
    GlCollapsibleListbox,
  },
  props: {
    multiple: {
      type: Boolean,
      required: false,
      default: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    /**
     * Array of branch names or single branch name
     */
    selected: {
      type: [Array, String, Number],
      required: false,
      default: () => [],
    },
    errorMessage: {
      type: String,
      required: false,
      default: null,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      branches: [],
      loading: false,
      openedOnce: false,
      selectedState: this.selected,
    };
  },
  computed: {
    customErrorMessage() {
      return this.errorMessage || this.$options.i18n.errorMessage;
    },
    listBoxItems() {
      return this.branches.map(({ name }) => ({ text: name, value: name }));
    },
    listBoxItemsNames() {
      return this.listBoxItems.map(({ value }) => value);
    },
    headerText() {
      const { headerTextMultiple, headerTextSingle } = this.$options.i18n;
      return this.multiple ? headerTextMultiple : headerTextSingle;
    },
    toggleText() {
      const { defaultToggleText, defaultToggleTextMultiple } = this.$options.i18n;
      const fallbackText = this.multiple ? defaultToggleTextMultiple : defaultToggleText;

      if (this.multiple && this.selected?.length > 0) {
        return this.selected?.join(', ');
      }

      if (!this.multiple) {
        if (Array.isArray(this.selected)) {
          return this.selected.length > 0 ? this.selectedState.join(', ') : fallbackText;
        }

        return this.selected || fallbackText;
      }

      return fallbackText;
    },
    category() {
      return this.hasError ? 'secondary' : 'primary';
    },
    variant() {
      return this.hasError ? 'danger' : 'default';
    },
  },
  created() {
    this.handleSearch = debounce(this.fetchBranches, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    async fetchBranches(term) {
      this.loading = true;

      try {
        this.branches = await Api.projectProtectedBranches(this.projectId, term);
        this.$emit('error', { hasErrored: false });
      } catch (error) {
        this.$emit('error', { hasErrored: true, error: this.customErrorMessage });
        this.branches = [];
        Sentry.captureException(error);
      } finally {
        this.loading = false;
        this.openedOnce = true;
      }
    },
    /**
     * @param value {Array|String} array for multiple string for single
     */
    handleSelect(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    :header-text="headerText"
    :loading="loading && !openedOnce"
    :items="listBoxItems"
    :multiple="multiple"
    :searching="loading"
    :reset-button-label="$options.i18n.resetLabel"
    :show-select-all-button-label="$options.i18n.selectAllLabel"
    :toggle-text="toggleText"
    :category="category"
    :variant="variant"
    :selected="selected"
    searchable
    @shown.once="fetchBranches"
    @search="handleSearch"
    @select="handleSelect"
    @select-all="handleSelect(listBoxItemsNames)"
    @reset="handleSelect([])"
  />
</template>
