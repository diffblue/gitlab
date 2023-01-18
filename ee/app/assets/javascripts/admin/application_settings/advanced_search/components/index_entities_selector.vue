<script>
import { debounce } from 'lodash';
import { GlAlert, GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  MINIMUM_QUERY_LENGTH,
  NO_RESULTS_TEXT,
  SEARCH_QUERY_TOO_SHORT,
  ENTITIES_FETCH_ERROR,
} from '../constants';

export default {
  components: {
    GlAlert,
    GlCollapsibleListbox,
  },
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
    apiPath: {
      type: String,
      required: true,
    },
    toggleText: {
      type: String,
      required: true,
    },
    nameProp: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searching: false,
      searchString: '',
      items: [],
      errorMessage: '',
    };
  },
  computed: {
    selectedIds() {
      return this.selected.map(({ id }) => id);
    },
    options() {
      return this.items
        .filter(({ id }) => !this.selectedIds.includes(id))
        .map((item) => ({
          text: item[this.nameProp],
          value: String(item.id),
        }));
    },
    isSearchQueryTooShort() {
      return this.searchString && this.searchString.length < MINIMUM_QUERY_LENGTH;
    },
    noResultsText() {
      return this.isSearchQueryTooShort
        ? this.$options.i18n.searchQueryTooShort
        : this.$options.i18n.noResultsText;
    },
  },
  methods: {
    onSearch: debounce(function debouncedSearch(searchString) {
      this.searchString = searchString;
      if (this.isSearchQueryTooShort) {
        this.items = [];
      } else {
        this.fetchItems();
      }
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    onSelect(value) {
      const selectedItem = this.items.find(({ id }) => String(id) === value);
      this.$emit('select', {
        id: selectedItem.id,
        text: selectedItem[this.nameProp],
      });
    },
    async fetchItems() {
      this.searching = true;
      try {
        const { data } = await axios.get(this.apiPath, {
          params: {
            search: this.searchString,
          },
        });
        this.items = data;
      } catch (error) {
        this.handleError({ message: ENTITIES_FETCH_ERROR, error });
      } finally {
        this.searching = false;
      }
    },
    handleError({ message, error }) {
      Sentry.captureException(error);
      this.errorMessage = message;
    },
    dismissError() {
      this.errorMessage = '';
    },
  },
  i18n: {
    noResultsText: NO_RESULTS_TEXT,
    searchQueryTooShort: SEARCH_QUERY_TOO_SHORT,
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" @dismiss="dismissError">{{
      errorMessage
    }}</gl-alert>
    <gl-collapsible-listbox
      searchable
      :searching="searching"
      :items="options"
      :toggle-text="toggleText"
      :no-results-text="noResultsText"
      @shown.once="fetchItems"
      @search="onSearch"
      @select="onSelect"
    />
  </div>
</template>
