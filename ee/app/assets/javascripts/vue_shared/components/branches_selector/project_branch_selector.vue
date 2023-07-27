<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { BRANCHES_PER_PAGE } from './constants';

export default {
  i18n: {
    defaultText: __('Select branches'),
    errorMessage: __(
      'Could not retrieve the list of branches. Use the YAML editor mode, or refresh this page later. To view the list of branches, go to %{boldStart}Code - Branches%{boldEnd}',
    ),
    resetLabel: __('Clear all'),
    selectAllLabel: __('Select all'),
  },
  name: 'ProjectBranchSelector',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    header: {
      type: String,
      required: false,
      default: null,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: [Array, String, Number],
      required: false,
      default: () => [],
    },
    text: {
      type: String,
      required: false,
      default: null,
    },
    errorMessage: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      branches: [],
      loading: false,
      openedOnce: false,
      limit: BRANCHES_PER_PAGE,
      totalBranches: BRANCHES_PER_PAGE,
    };
  },
  computed: {
    branchNames() {
      return this.branches.map(({ value }) => value);
    },
    category() {
      return this.hasError ? 'secondary' : 'primary';
    },
    variant() {
      return this.hasError ? 'danger' : 'default';
    },
    customErrorMessage() {
      return this.errorMessage || this.$options.i18n.errorMessage;
    },
    headerText() {
      return this.header || this.$options.i18n.defaultText;
    },
    toggleText() {
      if (this.selected?.length > 0) {
        return this.selected?.join(', ');
      }

      return this.text || this.$options.i18n.defaultText;
    },
  },
  created() {
    this.handleSearch = debounce(this.fetchBranches, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    handleSelect(value) {
      this.$emit('select', value);
    },
    async fetchBranches(searchTerm) {
      this.loading = true;

      try {
        const payload = await Api.branches(this.projectFullPath, searchTerm, {
          per_page: this.limit,
        });

        const totalBranches = payload.headers['x-total'];
        this.branches = payload.data.map(({ name }) => ({ value: name, text: name }));
        this.totalBranches = Number.parseInt(totalBranches, 10);
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
    onBottomReached() {
      if (this.limit >= this.totalBranches) {
        return;
      }

      this.limit += BRANCHES_PER_PAGE;
      this.fetchBranches();
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    multiple
    searchable
    infinite-scroll
    :category="category"
    :variant="variant"
    :infinite-scroll-loading="loading && openedOnce"
    :header-text="headerText"
    :loading="loading && !openedOnce"
    :items="branches"
    :reset-button-label="$options.i18n.resetLabel"
    :toggle-text="toggleText"
    :selected="selected"
    :show-select-all-button-label="$options.i18n.selectAllLabel"
    @bottom-reached="onBottomReached"
    @search="handleSearch"
    @select="handleSelect"
    @select-all="handleSelect(branchNames)"
    @shown.once="fetchBranches"
    @reset="handleSelect([])"
  />
</template>
