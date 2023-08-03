<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { BRANCHES_PER_PAGE } from './constants';

const branchListboxMapper = ({ name }) => ({ value: name, text: name });

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
      searchTerm: '',
      searching: false,
      page: 1,
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
    itemsLoadedLength() {
      return this.page * BRANCHES_PER_PAGE;
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
    this.search = debounce(this.fetchBranches, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    handleSearch(searchTerm) {
      this.searchTerm = searchTerm;
      this.searching = true;
      this.page = 1;
      this.branches = [];

      this.search(searchTerm);
    },
    handleSelect(value) {
      this.$emit('select', value);
    },
    async fetchBranches() {
      this.loading = true;

      try {
        const payload = await Api.branches(this.projectFullPath, this.searchTerm, {
          per_page: BRANCHES_PER_PAGE,
          page: this.page,
        });

        const totalBranches = payload.headers['x-total'];
        const items = payload.data.map(branchListboxMapper);

        this.branches = [...this.branches, ...items];
        this.totalBranches = Number.parseInt(totalBranches, 10);
        this.$emit('success');
      } catch (error) {
        this.$emit('error', { error: this.customErrorMessage });
        this.branches = [];
        Sentry.captureException(error);
      } finally {
        this.loading = false;
        this.openedOnce = true;
        this.searching = false;
      }
    },
    onBottomReached() {
      if (this.itemsLoadedLength >= this.totalBranches) {
        return;
      }

      this.page += 1;
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
    :searching="searching"
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
