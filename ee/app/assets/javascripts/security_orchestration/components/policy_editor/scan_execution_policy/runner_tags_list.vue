<script>
import { GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import projectRunnerTags from 'ee/security_orchestration/graphql/queries/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/security_orchestration/graphql/queries/get_group_runner_tags.query.graphql';
import { getUniqueTagListFromEdges } from 'ee/on_demand_scans_form/utils';

export default {
  name: 'RunnerTagsList',
  i18n: {
    runnerEmptyStateText: s__('SecurityOrchestration|No matching results'),
    noRunnerTagsText: s__('SecurityOrchestration|Selected automatically'),
    runnerSearchHeader: s__('SecurityOrchestration|Select runner tags'),
    resetButtonLabel: s__('SecurityOrchestration|Clear all'),
    runnersDisabledStateTooltip: s__(
      'SecurityOrchestration|Scan will automatically choose a runner to run on because there are no tags exist on runners',
    ),
  },
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
      },
      error({ message }) {
        this.$emit('error', message);
      },
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
    },
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
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
  },
  data() {
    return {
      search: '',
      tags: [],
      selected: [],
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.tagList.loading;
    },
    filteredUnselectedItems() {
      return this.tags
        .filter((tag) => tag.includes(this.search))
        .map((tag) => ({ text: tag, value: tag }));
    },
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    isTagListEmpty() {
      return this.tags.length === 0;
    },
    tooltipTitle() {
      return this.isTagListEmpty ? this.$options.i18n.runnersDisabledStateTooltip : '';
    },
    tagListQuery() {
      return this.isProject ? projectRunnerTags : groupRunnerTags;
    },
    text() {
      if (this.isTagListEmpty) {
        return this.$options.i18n.noRunnerTagsText;
      }

      return this.selected?.join(', ') || this.$options.i18n.runnerSearchHeader;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    doesTagExist(tag) {
      return this.tags.includes(tag);
    },
    hideDropdown() {
      this.sortTags();
    },
    isTagSelected(tag) {
      return this.selected?.includes(tag);
    },
    selectExistingTags() {
      if (this.value.length > 0) {
        this.selected = this.value.filter((tag) => this.doesTagExist(tag));
      }
    },
    setSelection(tags) {
      this.selected = tags;
      this.$emit('input', this.selected);
    },
    setSearchKey(value) {
      this.search = value?.trim();
    },
    sortTags() {
      this.tags.sort((a) => (this.isTagSelected(a) ? -1 : 1));
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-gl-tooltip
    multiple
    searchable
    toggle-class="gl-max-w-80"
    :disabled="isTagListEmpty"
    :items="filteredUnselectedItems"
    :loading="loading"
    :header-text="$options.i18n.runnerSearchHeader"
    :no-caret="isTagListEmpty"
    :no-results-text="$options.i18n.runnerEmptyStateText"
    :selected="selected"
    :reset-button-label="$options.i18n.resetButtonLabel"
    :toggle-text="text"
    :title="tooltipTitle"
    @hidden="sortTags"
    @reset="setSelection([])"
    @search="debouncedSearchKeyUpdate"
    @select="setSelection"
  />
</template>
