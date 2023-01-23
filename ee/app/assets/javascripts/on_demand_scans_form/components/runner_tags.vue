<script>
import { debounce } from 'lodash';
import { GlLink, GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { HELP_PAGE_RUNNER_TAGS_PATH } from 'ee/on_demand_scans/constants';
import getAllProjectRunners from '../graphql/all_runners.query.graphql';
import { ERROR_MESSAGES, ERROR_FETCH_RUNNER_TAGS } from '../settings';
import { getUniqueTagListFromEdges } from '../utils';

export default {
  HELP_PAGE_RUNNER_TAGS_PATH,
  i18n: {
    runnerEmptyStateText: s__('OnDemandScans|No matching results'),
    runnerSearchHeader: s__('OnDemandScans|Select runner tags'),
    runnerTagsLabel: s__(
      'OnDemandScans|Use runner tags to select specific runners for this security scan. %{linkStart}What are runner tags?%{linkEnd}',
    ),
  },
  name: 'RunnerTags',
  components: {
    GlLink,
    GlCollapsibleListbox,
    GlSprintf,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    value: {
      type: Array,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      search: '',
      isLoading: false,
      selected: [],
      tags: [],
    };
  },
  computed: {
    isListEmpty() {
      return this.filteredUnselectedItems.length === 0;
    },
    filteredUnselectedItems() {
      return this.tags
        .filter((tag) => tag.includes(this.search))
        .map((tag) => ({ text: tag, value: tag }));
    },
    text() {
      return this.selected?.join(', ') || this.$options.i18n.runnerSearchHeader;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

    if (this.value?.length > 0) {
      this.selected = this.value;
    }
  },
  methods: {
    async fetchRunners() {
      try {
        if (this.isListEmpty) {
          this.isLoading = true;
          const { data } = await this.$apollo.query({
            query: getAllProjectRunners,
            variables: {
              fullPath: this.projectPath,
            },
          });

          const {
            project: {
              runners: { nodes = [] },
            },
          } = data;

          this.tags = getUniqueTagListFromEdges(nodes);
        }
        this.sortTags();
      } catch (error) {
        this.$emit('error', error?.message || ERROR_MESSAGES[ERROR_FETCH_RUNNER_TAGS]);
      } finally {
        this.isLoading = false;
      }
    },
    setSearchKey(value) {
      this.search = value?.trim();
    },
    sortTags() {
      this.tags.sort((a) => (this.isTagSelected(a) ? -1 : 1));
    },
    isTagSelected(tag) {
      return this.selected?.includes(tag);
    },
    setSelection(tags) {
      this.selected = tags;
      this.$emit('input', this.selected);
    },
    hideDropdown() {
      this.sortTags();
    },
  },
};
</script>

<template>
  <div>
    <gl-sprintf :message="$options.i18n.runnerTagsLabel" class="form-text text-gl-muted gl-mb-5">
      <template #link="{ content }">
        <gl-link :href="$options.HELP_PAGE_RUNNER_TAGS_PATH" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>

    <gl-collapsible-listbox
      class="gl-mt-3"
      :block="true"
      :items="filteredUnselectedItems"
      :loading="isLoading"
      :header-text="$options.i18n.runnerSearchHeader"
      :multiple="true"
      :no-results-text="$options.i18n.runnerEmptyStateText"
      :searchable="true"
      :selected="selected"
      toggle-class="gl-w-full"
      :toggle-text="text"
      @hidden="hideDropdown"
      @search="debouncedSearchKeyUpdate"
      @select="setSelection"
      @shown.once="fetchRunners"
    />
  </div>
</template>
