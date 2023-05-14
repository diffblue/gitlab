<script>
import {
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlSprintf,
  GlPopover,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import { helpPagePath } from '~/helpers/help_page_helper';
import { validateHexColor } from '~/lib/utils/color_utils';
import { s__ } from '~/locale';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';
import { DEBOUNCE_DELAY } from '../constants';
import { fetchPipelineConfigurationFileExists, validatePipelineConfirmationFormat } from '../utils';

export default {
  components: {
    ColorPicker,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
    GlPopover,
  },
  inject: ['pipelineConfigurationFullPathEnabled', 'pipelineConfigurationEnabled'],
  props: {
    color: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: false,
      default: null,
    },
    pipelineConfigurationFullPath: {
      type: String,
      required: false,
      default: null,
    },
    submitButtonText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      pipelineConfigurationFileExists: true,
    };
  },
  computed: {
    isValidColor() {
      return validateHexColor(this.color);
    },
    isValidName() {
      if (this.name === null) {
        return null;
      }

      return Boolean(this.name);
    },
    isValidDescription() {
      if (this.description === null) {
        return null;
      }

      return Boolean(this.description);
    },
    isValidPipelineConfiguration() {
      if (!this.pipelineConfigurationFullPath) {
        return null;
      }

      return this.isValidPipelineConfigurationFormat && this.pipelineConfigurationFileExists;
    },
    isValidPipelineConfigurationFormat() {
      return validatePipelineConfirmationFormat(this.pipelineConfigurationFullPath);
    },
    disableSubmitBtn() {
      return (
        !this.isValidName ||
        !this.isValidDescription ||
        !this.isValidColor ||
        this.isValidPipelineConfiguration === false
      );
    },
    pipelineConfigurationFeedbackMessage() {
      if (!this.isValidPipelineConfigurationFormat) {
        return this.$options.i18n.pipelineConfigurationInputInvalidFormat;
      }

      return this.$options.i18n.pipelineConfigurationInputUnknownFile;
    },
    compliancePipelineConfigurationHelpPath() {
      return helpPagePath('user/group/compliance_frameworks.md', {
        anchor: 'example-configuration',
      });
    },
  },
  async created() {
    if (this.pipelineConfigurationFullPath) {
      this.validatePipelineConfigurationPath(this.pipelineConfigurationFullPath);
    }
  },
  methods: {
    onSubmit() {
      this.$emit('submit');
    },
    onPipelineInput(path) {
      this.$emit('update:pipelineConfigurationFullPath', path);
      this.validatePipelineInput(path);
    },
    async validatePipelineConfigurationPath(path) {
      this.pipelineConfigurationFileExists = await fetchPipelineConfigurationFileExists(path);
    },
    validatePipelineInput: debounce(function debounceValidation(path) {
      this.validatePipelineConfigurationPath(path);
    }, DEBOUNCE_DELAY),
    onCancel(event) {
      event.preventDefault();
      this.$emit('cancel');
    },
  },
  i18n: {
    titleInputLabel: s__('ComplianceFrameworks|Name'),
    titleInputInvalid: s__('ComplianceFrameworks|Name is required'),
    descriptionInputLabel: s__('ComplianceFrameworks|Description'),
    descriptionInputInvalid: s__('ComplianceFrameworks|Description is required'),
    pipelineConfigurationInputLabel: s__(
      'ComplianceFrameworks|Compliance pipeline configuration (optional)',
    ),
    pipelineConfigurationInputDescription: s__(
      'ComplianceFrameworks|Required format: %{codeStart}path/file.y[a]ml@group-name/project-name%{codeEnd}. %{linkStart}See some examples%{linkEnd}.',
    ),
    pipelineConfigurationInputDisabledPopoverTitle: s__(
      'ComplianceFrameworks|Requires Ultimate subscription',
    ),
    pipelineConfigurationInputDisabledPopoverContent: s__(
      'ComplianceFrameworks|Set compliance pipeline configuration for projects that use this framework. %{linkStart}How do I create the configuration?%{linkEnd}',
    ),
    pipelineConfigurationInputDisabledPopoverLink: helpPagePath(
      'user/group/compliance_frameworks.html#compliance-pipelines',
    ),
    pipelineConfigurationInputInvalidFormat: s__('ComplianceFrameworks|Invalid format'),
    pipelineConfigurationInputUnknownFile: s__('ComplianceFrameworks|Configuration not found'),
    colorInputLabel: s__('ComplianceFrameworks|Background color'),
    cancelBtnText: s__('ComplianceFrameworks|Cancel'),
  },
  disabledPipelineConfigurationInputPopoverTarget:
    'disabled-pipeline-configuration-input-popover-target',
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-form-group
      :label="$options.i18n.titleInputLabel"
      :invalid-feedback="$options.i18n.titleInputInvalid"
      :state="isValidName"
      data-testid="name-input-group"
    >
      <gl-form-input
        :value="name"
        :state="isValidName"
        data-testid="name-input"
        @input="$emit('update:name', $event)"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.descriptionInputLabel"
      :invalid-feedback="$options.i18n.descriptionInputInvalid"
      :state="isValidDescription"
      data-testid="description-input-group"
    >
      <gl-form-input
        :value="description"
        :state="isValidDescription"
        data-testid="description-input"
        @input="$emit('update:description', $event)"
      />
    </gl-form-group>

    <gl-form-group
      v-if="pipelineConfigurationFullPathEnabled && pipelineConfigurationEnabled"
      :label="$options.i18n.pipelineConfigurationInputLabel"
      label-for="pipeline-configuration-input"
      :invalid-feedback="pipelineConfigurationFeedbackMessage"
      :state="isValidPipelineConfiguration"
      data-testid="pipeline-configuration-input-group"
    >
      <template #description>
        <gl-sprintf :message="$options.i18n.pipelineConfigurationInputDescription">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>

          <template #link="{ content }">
            <gl-link :href="compliancePipelineConfigurationHelpPath" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <gl-form-input
        id="pipeline-configuration-input"
        :value="pipelineConfigurationFullPath"
        :state="isValidPipelineConfiguration"
        data-testid="pipeline-configuration-input"
        @input="onPipelineInput"
      />
    </gl-form-group>

    <template v-if="!pipelineConfigurationEnabled">
      <gl-form-group
        id="disabled-pipeline-configuration-input-group"
        :label="$options.i18n.pipelineConfigurationInputLabel"
        label-for="disabled-pipeline-configuration-input"
        data-testid="disabled-pipeline-configuration-input-group"
      >
        <div :id="$options.disabledPipelineConfigurationInputPopoverTarget" tabindex="0">
          <gl-form-input
            id="disabled-pipeline-configuration-input"
            disabled
            data-testid="disabled-pipeline-configuration-input"
          />
        </div>
      </gl-form-group>
      <gl-popover
        :title="$options.i18n.pipelineConfigurationInputDisabledPopoverTitle"
        show-close-button
        :target="$options.disabledPipelineConfigurationInputPopoverTarget"
        data-testid="disabled-pipeline-configuration-input-popover"
      >
        <p class="gl-mb-0">
          <gl-sprintf :message="$options.i18n.pipelineConfigurationInputDisabledPopoverContent">
            <template #link="{ content }">
              <gl-link
                :href="$options.i18n.pipelineConfigurationInputDisabledPopoverLink"
                target="_blank"
                class="gl-font-sm"
              >
                {{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </p>
      </gl-popover>
    </template>

    <color-picker
      :value="color"
      :label="$options.i18n.colorInputLabel"
      :state="isValidColor"
      @input="$emit('update:color', $event)"
    />

    <div
      class="gl-display-flex gl-pt-5 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100 gl-justify-content-end gl-gap-3"
    >
      <gl-button data-testid="cancel-btn" @click="onCancel">{{
        $options.i18n.cancelBtnText
      }}</gl-button>
      <gl-button
        type="submit"
        variant="confirm"
        class="js-no-auto-disable"
        data-testid="submit-btn"
        :disabled="disableSubmitBtn"
        >{{ submitButtonText }}</gl-button
      >
    </div>
  </gl-form>
</template>
