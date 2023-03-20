<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { HELP_PAGE_RUNNER_TAGS_PATH } from 'ee/on_demand_scans/constants';
import RunnerTagsDropdown from 'ee/vue_shared/components/runner_tags_dropdown/runner_tags_dropdown.vue';
import { ERROR_MESSAGES, ERROR_FETCH_RUNNER_TAGS } from '../settings';

export default {
  HELP_PAGE_RUNNER_TAGS_PATH,
  i18n: {
    runnerSearchHeader: s__('OnDemandScans|Select runner tags'),
    runnerTagsLabel: s__(
      'OnDemandScans|%{textStart}Tags specify which runners process this scan. Runners must have every tag selected.%{textEnd} %{linkStart}What are runner tags?%{linkEnd}',
    ),
  },
  name: 'RunnerTags',
  components: {
    GlLink,
    GlSprintf,
    RunnerTagsDropdown,
  },
  props: {
    canEditRunnerTags: {
      type: Boolean,
      required: false,
      default: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      selected: [],
    };
  },
  computed: {
    isRunnerTagsDisabled() {
      return !this.canEditRunnerTags;
    },
  },
  methods: {
    emitErrorMessage(error) {
      this.$emit('error', error?.message || ERROR_MESSAGES[ERROR_FETCH_RUNNER_TAGS]);
    },
    setSelection(tags) {
      this.selected = tags;
      this.$emit('input', this.selected);
    },
  },
};
</script>

<template>
  <div>
    <gl-sprintf :message="$options.i18n.runnerTagsLabel" class="form-text gl-mb-5">
      <template #text="{ content }">
        <p class="gl-m-0 gl-text-secondary">{{ content }}</p>
      </template>
      <template #link="{ content }">
        <gl-link :href="$options.HELP_PAGE_RUNNER_TAGS_PATH" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>

    <runner-tags-dropdown
      toggle-class="gl-w-full gl-mb-1! gl-mt-4"
      :block="true"
      :disabled="isRunnerTagsDisabled"
      :empty-tags-list-placeholder="$options.i18n.noRunnerTagsText"
      :namespace-path="projectPath"
      :value="value"
      @input="setSelection"
      @error="emitErrorMessage"
    />
  </div>
</template>
