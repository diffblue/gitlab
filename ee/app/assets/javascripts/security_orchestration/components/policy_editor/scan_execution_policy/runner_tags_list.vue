<script>
import { GlCollapsibleListbox, GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getBaseURL } from '~/lib/utils/url_utility';
import RunnerTagsDropdown from 'ee/vue_shared/components/runner_tags_dropdown/runner_tags_dropdown.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  TAGS_MODE_SELECTED_ITEMS,
  POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
  POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
} from './constants';

export default {
  TAGS_MODES: TAGS_MODE_SELECTED_ITEMS,
  name: 'RunnerTagsList',
  i18n: {
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
    RunnerTagsDropdown,
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
      tags: [],
      selected: [],
      selectedTagsText: this.$options.TAGS_MODES[0].text,
      selectedTagsMode: POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
      isTagListEmpty: false,
    };
  },
  computed: {
    isSpecificTagMode() {
      return this.selectedTagsMode === POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY;
    },
    isTagsListVisible() {
      return this.isSpecificTagMode && !this.isTagListEmpty;
    },
    runnersTagLink() {
      if (this.namespaceType === NAMESPACE_TYPES.GROUP) {
        return `${getBaseURL()}/groups/${this.namespacePath}/-/runners`;
      }

      return `${getBaseURL()}/${this.namespacePath}/-/runners`;
    },
  },
  methods: {
    setSelection(tags) {
      this.selected = tags;
      this.$emit('input', this.selected);
    },
    setSelectedTagsMode(key) {
      this.selectedTagsText = this.$options.TAGS_MODES.find(({ value }) => value === key)?.text;
      this.selectedTagsMode = key;

      if (key === POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY) {
        this.setSelection([]);
      }
    },
    setTags(tags) {
      this.tags = tags;
      this.isTagListEmpty = this.tags.length === 0;

      if (this.isTagListEmpty) {
        this.setSelectedTagsMode(POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY);
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

    <runner-tags-dropdown
      v-if="isTagsListVisible"
      toggle-class="gl-max-w-62 gl-ml-2"
      :empty-tags-list-placeholder="$options.i18n.noRunnerTagsText"
      :namespace-path="namespacePath"
      :namespace-type="namespaceType"
      :value="value"
      @input="setSelection"
      @tags-loaded="setTags"
      @error="$emit('error')"
    />
  </div>
</template>
