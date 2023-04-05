<script>
import { sprintf } from '~/locale';
import ApprovalSettingsCheckbox from 'ee/approvals/components/approval_settings_checkbox.vue';
import { I18N } from '../constants';

export default {
  name: 'MergeChecksApp',
  components: {
    ApprovalSettingsCheckbox,
  },
  inject: [
    'sourceType',
    'parentGroupName',
    'pipelineMustSucceed',
    'allowMergeOnSkippedPipeline',
    'onlyAllowMergeIfAllResolved',
  ],
  data() {
    // map the initial values for two way binding.
    const { pipelineMustSucceed, allowMergeOnSkippedPipeline, onlyAllowMergeIfAllResolved } = this;
    return {
      hasPipelineMustSucceed: pipelineMustSucceed.value,
      hasAllowMergeOnSkippedPipeline: allowMergeOnSkippedPipeline.value,
      hasOnlyAllowMergeIfAllResolved: onlyAllowMergeIfAllResolved.value,
    };
  },
  computed: {
    lockedText() {
      return sprintf(I18N.lockedText, { groupName: this.parentGroupName });
    },
    skippedPipelineLocked() {
      return this.allowMergeOnSkippedPipeline.locked || !this.hasPipelineMustSucceed;
    },
    skippedPipelineText() {
      return this.hasPipelineMustSucceed ? this.lockedText : I18N.lockedUponPipelineMustSucceed;
    },
    skippedPipelineChecked() {
      return this.hasPipelineMustSucceed && this.hasAllowMergeOnSkippedPipeline;
    },
  },
  methods: {
    formName(name) {
      return `${this.sourceType}[${name}]`;
    },
    toggleChecked(name) {
      this[name] = !this[name];
    },
  },
  i18n: I18N,
};
</script>
<template>
  <div>
    <input
      :name="formName('only_allow_merge_if_pipeline_succeeds')"
      :value="hasPipelineMustSucceed"
      type="hidden"
    />
    <approval-settings-checkbox
      :label="$options.i18n.pipelineMustSucceed.label"
      :checked="hasPipelineMustSucceed"
      :locked="pipelineMustSucceed.locked"
      :locked-text="lockedText"
      checkbox-qa-selector="only_allow_merge_if_pipeline_succeeds_checkbox"
      data-testid="allow_merge_if_pipeline_succeeds_checkbox"
      @input="toggleChecked('hasPipelineMustSucceed')"
    >
      <template #help>{{ $options.i18n.pipelineMustSucceed.help }}</template>
    </approval-settings-checkbox>
    <div class="gl-pl-6">
      <input
        :name="formName('allow_merge_on_skipped_pipeline')"
        :value="skippedPipelineChecked"
        type="hidden"
      />
      <approval-settings-checkbox
        :label="$options.i18n.allowMergeOnSkipped.label"
        :checked="skippedPipelineChecked"
        :locked="skippedPipelineLocked"
        :locked-text="skippedPipelineText"
        checkbox-qa-selector="always_allow_merge_on_skipped_pipeline_checkbox"
        data-testid="allow_merge_on_skipped_pipeline_checkbox"
        @input="toggleChecked('hasAllowMergeOnSkippedPipeline')"
      >
        <template #help>{{ $options.i18n.allowMergeOnSkipped.help }}</template>
      </approval-settings-checkbox>
    </div>
    <input
      :name="formName('only_allow_merge_if_all_discussions_are_resolved')"
      :value="hasOnlyAllowMergeIfAllResolved"
      type="hidden"
    />
    <approval-settings-checkbox
      :label="$options.i18n.onlyMergeWhenAllResolvedLabel"
      :checked="hasOnlyAllowMergeIfAllResolved"
      :locked="onlyAllowMergeIfAllResolved.locked"
      :locked-text="lockedText"
      checkbox-qa-selector="only_allow_merge_if_all_discussions_are_resolved_checkbox"
      data-testid="allow_merge_if_all_discussions_are_resolved_checkbox"
      @input="toggleChecked('hasOnlyAllowMergeIfAllResolved')"
    />
  </div>
</template>
