<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownForm,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlTooltip,
} from '@gitlab/ui';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { isValidSha1Hash } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import { INPUT_DEBOUNCE, CUSTODY_REPORT_PARAMETER } from '../../../constants';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownForm,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    mergeCommitsCsvExportPath: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      validMergeCommitHash: null,
      listMergeCommitsButton: null,
    };
  },
  computed: {
    mergeCommitButtonDisabled() {
      return !this.validMergeCommitHash;
    },
  },
  mounted() {
    this.listMergeCommitsButton = this.$refs.listMergeCommitsButton;
  },
  methods: {
    onInput(value) {
      this.validMergeCommitHash = isValidSha1Hash(value);
    },
  },
  strings: {
    listMergeCommitsButtonText: __('List of all commits'),
    mergeCommitInputLabel: __('Commit SHA'),
    mergeCommitInvalidMessage: __('Invalid hash'),
    mergeCommitButtonText: __('Export commit custody report'),
    exportAsCsv: __('Export as CSV'),
    csvSizeLimit: __('(max size 15 MB)'),
  },
  inputDebounce: INPUT_DEBOUNCE,
  custodyReportParamater: CUSTODY_REPORT_PARAMETER,
};
</script>

<template>
  <div>
    <gl-dropdown data-testid="merge-commit-dropdown" split>
      <template #button-content>
        <gl-button
          ref="listMergeCommitsButton"
          class="gl-p-0!"
          category="tertiary"
          icon="export"
          :href="mergeCommitsCsvExportPath"
        >
          {{ $options.strings.listMergeCommitsButtonText }}
        </gl-button>
      </template>
      <gl-dropdown-form>
        <gl-form :action="mergeCommitsCsvExportPath" class="gl-px-3" method="GET">
          <gl-form-group
            :label="$options.strings.mergeCommitInputLabel"
            :invalid-feedback="$options.strings.mergeCommitInvalidMessage"
            :state="validMergeCommitHash"
            label-size="sm"
            label-for="merge-commits-export-custody-report"
          >
            <gl-form-input
              id="merge-commits-export-custody-report"
              :name="$options.custodyReportParamater"
              :debounce="$options.inputDebounce"
              @input="onInput"
            />
          </gl-form-group>
          <gl-button
            :disabled="mergeCommitButtonDisabled"
            type="submit"
            variant="confirm"
            data-test-id="merge-commit-submit-button"
            class="disable-hover"
            >{{ $options.strings.mergeCommitButtonText }}</gl-button
          >
        </gl-form>
      </gl-dropdown-form>
    </gl-dropdown>
    <gl-tooltip
      v-if="listMergeCommitsButton"
      :target="listMergeCommitsButton"
      boundary="viewport"
      placement="top"
    >
      <p class="gl-my-0">{{ $options.strings.exportAsCsv }}</p>
      <p class="gl-my-0">{{ $options.strings.csvSizeLimit }}</p>
    </gl-tooltip>
  </div>
</template>
