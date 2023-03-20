<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import projectRunnerTags from './graphql/get_project_runner_tags.query.graphql';
import groupRunnerTags from './graphql/get_group_runner_tags.query.graphql';
import { NAMESPACE_TYPES } from './constants';
import { getUniqueTagListFromEdges } from './utils';

export default {
  i18n: {
    noRunnerTagsText: s__('RunnerTags|No tags exist'),
    runnerEmptyStateText: s__('RunnerTags|No matching results'),
    runnerSearchHeader: s__('RunnerTags|Select runner tags'),
  },
  name: 'RunnerTagsDropdown',
  components: {
    GlCollapsibleListbox,
  },
  apollo: {
    tagList: {
      query() {
        return this.tagListQuery;
      },
      update(data) {
        const {
          [this.namespaceType]: {
            runners: { nodes = [] },
          },
        } = data;
        this.tags = getUniqueTagListFromEdges(nodes);
        this.selectExistingTags();
        this.sortTags();

        this.$emit('tags-loaded', this.tags);
      },
      error(error) {
        this.$emit('error', error);
      },
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
    },
  },
  props: {
    block: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    namespaceType: {
      type: String,
      required: false,
      default: NAMESPACE_TYPES.PROJECT,
    },
    namespacePath: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    headerText: {
      type: String,
      required: false,
      default: '',
    },
    emptyTagsListPlaceholder: {
      type: String,
      required: false,
      default: '',
    },
    toggleClass: {
      type: [String, Array, Object],
      required: false,
      default: null,
    },
  },
  data() {
    return {
      search: '',
      tags: [],
      selected: [],
    };
  },
  computed: {
    filteredUnselectedItems() {
      return this.tags
        .filter((tag) => tag.includes(this.search))
        .map((tag) => ({ text: tag, value: tag }));
    },
    isDropdownDisabled() {
      return this.disabled || this.isTagListEmpty;
    },
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    isTagListEmpty() {
      return this.tags.length === 0;
    },
    loading() {
      return this.$apollo.queries.tagList?.loading || false;
    },
    runnerSearchHeader() {
      return this.headerText || this.$options.i18n.runnerSearchHeader;
    },
    text() {
      if (this.isTagListEmpty) {
        return this.emptyTagsListPlaceholder || this.$options.i18n.noRunnerTagsText;
      }

      return this.selected?.join(', ') || this.$options.i18n.runnerSearchHeader;
    },
    tagListQuery() {
      return this.isProject ? projectRunnerTags : groupRunnerTags;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    isTagSelected(tag) {
      return this.selected?.includes(tag);
    },
    doesTagExist(tag) {
      return this.tags.includes(tag);
    },
    sortTags() {
      this.tags.sort((a) => (this.isTagSelected(a) ? -1 : 1));
    },
    setSearchKey(value) {
      this.search = value?.trim();
    },
    setSelection(tags) {
      this.selected = tags;
      this.$emit('input', this.selected);
    },
    selectExistingTags() {
      if (this.value.length > 0) {
        const nonExistingTags = this.value.filter((tag) => !this.doesTagExist(tag));

        if (nonExistingTags.length > 0) {
          this.$emit('error');
          return;
        }

        this.selected = this.value;
      }
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    multiple
    searchable
    data-testid="runner-tags-list"
    :block="block"
    :disabled="isDropdownDisabled"
    :toggle-class="toggleClass"
    :items="filteredUnselectedItems"
    :loading="loading"
    :header-text="runnerSearchHeader"
    :no-caret="isTagListEmpty"
    :no-results-text="$options.i18n.runnerEmptyStateText"
    :selected="selected"
    :reset-button-label="$options.i18n.resetButtonLabel"
    :toggle-text="text"
    @hidden="sortTags"
    @reset="setSelection([])"
    @search="debouncedSearchKeyUpdate"
    @select="setSelection"
  />
</template>
