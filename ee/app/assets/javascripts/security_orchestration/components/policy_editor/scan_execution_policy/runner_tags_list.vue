<script>
import { GlCollapsibleListbox, GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { getBaseURL } from '~/lib/utils/url_utility';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import projectRunnerTags from 'ee/security_orchestration/graphql/queries/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/security_orchestration/graphql/queries/get_group_runner_tags.query.graphql';
import { getUniqueTagListFromEdges } from 'ee/on_demand_scans_form/utils';
import {
  TAGS_MODE_SELECTED_ITEMS,
  POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
  POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
} from './constants';

export default {
  TAGS_MODES: TAGS_MODE_SELECTED_ITEMS,
  name: 'RunnerTagsList',
  i18n: {
    runnerEmptyStateText: s__('SecurityOrchestration|No matching results'),
    noRunnerTagsText: s__('SecurityOrchestration|Selected automatically'),
    runnerSearchHeader: s__('SecurityOrchestration|Select runner tags'),
    resetButtonLabel: s__('SecurityOrchestration|Clear all'),
    runnersDisabledStatePopoverTitle: s__('SecurityOrchestration|No tags available'),
    runnersDisabledStatePopoverContent: s__(
      'SecurityOrchestration|Scan will automatically choose a runner to run on because there are no tags exist on runners. You can %{linkStart}create a new tag in settings%{linkEnd}.',
    ),
  },
  components: {
    GlPopover,
    GlLink,
    GlCollapsibleListbox,
    GlSprintf,
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
      error() {
        this.$emit('error');
      },
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
    },
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
      selectedTagsText: this.$options.TAGS_MODES[0].text,
      selectedTagsMode: POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
    };
  },
  computed: {
    isSpecificTagMode() {
      return this.selectedTagsMode === POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY;
    },
    isTagsListVisible() {
      return this.isSpecificTagMode && !this.isTagListEmpty;
    },
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
    tagListQuery() {
      return this.isProject ? projectRunnerTags : groupRunnerTags;
    },
    text() {
      if (this.isTagListEmpty) {
        return this.$options.i18n.noRunnerTagsText;
      }

      return this.selected?.join(', ') || this.$options.i18n.runnerSearchHeader;
    },
    runnersTagLink() {
      if (this.namespaceType === NAMESPACE_TYPES.GROUP) {
        return `${getBaseURL()}/groups/${this.namespacePath}/-/runners`;
      }

      return `${getBaseURL()}/${this.namespacePath}/-/runners`;
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
      if (this.isTagListEmpty) {
        this.setSelectedTagsMode(POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY);
      }

      if (this.value.length > 0) {
        const nonExistingTags = this.value.filter((tag) => !this.doesTagExist(tag));

        if (nonExistingTags.length > 0) {
          this.$emit('error');
          return;
        }

        this.selected = this.value;
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
    setSelectedTagsMode(key) {
      this.selectedTagsText = this.$options.TAGS_MODES.find(({ value }) => value === key)?.text;
      this.selectedTagsMode = key;

      if (key === POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY) {
        this.setSelection([]);
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      id="runner-tags-switcher-id"
      data-testid="runner-tags-switcher"
      :disabled="isTagListEmpty"
      :items="$options.TAGS_MODES"
      :loading="loading"
      :selected="selectedTagsMode"
      :toggle-text="selectedTagsText"
      @select="setSelectedTagsMode"
    />
    <gl-popover
      v-if="isTagListEmpty"
      target="runner-tags-switcher-id"
      :title="$options.i18n.runnersDisabledStatePopoverTitle"
    >
      <gl-sprintf :message="$options.i18n.runnersDisabledStatePopoverContent">
        <template #link="{ content }">
          <gl-link class="gl-font-sm" :href="runnersTagLink">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-popover>

    <gl-collapsible-listbox
      v-if="isTagsListVisible"
      multiple
      searchable
      data-testid="runner-tags-list"
      toggle-class="gl-max-w-62 gl-ml-2"
      :items="filteredUnselectedItems"
      :loading="loading"
      :header-text="$options.i18n.runnerSearchHeader"
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
  </div>
</template>
