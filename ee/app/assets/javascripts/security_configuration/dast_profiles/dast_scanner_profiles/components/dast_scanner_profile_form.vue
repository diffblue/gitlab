<script>
import {
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlFormRadioGroup,
  GlFormRadio,
  GlInputGroupText,
} from '@gitlab/ui';
import { initFormField } from 'ee/security_configuration/utils';
import { serializeFormObject } from '~/lib/utils/forms';
import { s__ } from '~/locale';
import BaseDastProfileForm from '../../components/base_dast_profile_form.vue';
import dastProfileFormMixin from '../../dast_profile_form_mixin';
import { SCAN_TYPE, SCAN_TYPE_OPTIONS } from '../constants';
import dastScannerProfileCreateMutation from '../graphql/dast_scanner_profile_create.mutation.graphql';
import dastScannerProfileUpdateMutation from '../graphql/dast_scanner_profile_update.mutation.graphql';
import TooltipIcon from './tooltip_icon.vue';

const SPIDER_TIMEOUT_MIN = 0;
const SPIDER_TIMEOUT_MAX = 2880;
const TARGET_TIMEOUT_MIN = 1;
const TARGET_TIMEOUT_MAX = 3600;

export default {
  dastScannerProfileCreateMutation,
  dastScannerProfileUpdateMutation,
  name: 'DastScannerProfileForm',
  components: {
    BaseDastProfileForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlFormRadioGroup,
    GlFormRadio,
    GlInputGroupText,
    TooltipIcon,
  },
  mixins: [dastProfileFormMixin()],
  data() {
    const {
      profileName = '',
      spiderTimeout = 1,
      targetTimeout = 60,
      scanType = SCAN_TYPE.PASSIVE,
      useAjaxSpider = false,
      showDebugMessages = false,
    } = this.profile;

    const form = {
      state: false,
      showValidation: false,
      fields: {
        profileName: initFormField({ value: profileName }),
        spiderTimeout: initFormField({ value: spiderTimeout }),
        targetTimeout: initFormField({ value: targetTimeout }),
        scanType: initFormField({ value: scanType, required: false, skipValidation: true }),
        useAjaxSpider: initFormField({
          value: useAjaxSpider,
          required: false,
          skipValidation: true,
        }),
        showDebugMessages: initFormField({
          value: showDebugMessages,
          required: false,
          skipValidation: true,
        }),
      },
    };

    return {
      form,
      initialFormValues: serializeFormObject(form.fields),
    };
  },
  spiderTimeoutRange: {
    min: SPIDER_TIMEOUT_MIN,
    max: SPIDER_TIMEOUT_MAX,
  },
  targetTimeoutRange: {
    min: TARGET_TIMEOUT_MIN,
    max: TARGET_TIMEOUT_MAX,
  },
  SCAN_TYPE_OPTIONS,
  computed: {
    i18n() {
      const { isEdit } = this;
      return {
        title: isEdit
          ? s__('DastProfiles|Edit scanner profile')
          : s__('DastProfiles|New scanner profile'),
        errorMessage: isEdit
          ? s__('DastProfiles|Could not update the scanner profile. Please try again.')
          : s__('DastProfiles|Could not create the scanner profile. Please try again.'),
        tooltips: {
          spiderTimeout: s__(
            'DastProfiles|The maximum number of minutes allowed for the spider to traverse the site.',
          ),
          targetTimeout: s__(
            'DastProfiles|The maximum number of seconds allowed for the site under test to respond to a request.',
          ),
          scanMode: s__(
            'DastProfiles|A passive scan monitors all HTTP messages (requests and responses) sent to the target. An active scan attacks the target to find potential vulnerabilities.',
          ),
          ajaxSpider: s__(
            'DastProfiles|Run the AJAX spider, in addition to the traditional spider, to crawl the target site.',
          ),
          debugMessage: s__('DastProfiles|Include debug messages in the DAST console output.'),
          disabledProfileName: s__('DastProfiles|Profile in use and cannot be renamed'),
        },
      };
    },
    mutationVariables() {
      return {
        ...(this.isEdit ? { id: this.profile.id } : { fullPath: this.projectFullPath }),
        ...serializeFormObject(this.form.fields),
      };
    },
  },
};
</script>

<template>
  <base-dast-profile-form
    v-bind="$attrs"
    :profile="profile"
    :mutation="
      isEdit ? $options.dastScannerProfileUpdateMutation : $options.dastScannerProfileCreateMutation
    "
    :mutation-type="isEdit ? 'dastScannerProfileUpdate' : 'dastScannerProfileCreate'"
    :mutation-variables="mutationVariables"
    :form-touched="formTouched"
    :is-policy-profile="isPolicyProfile"
    :block-submit="!form.state"
    :show-header="!stacked"
    @submit="form.showValidation = true"
    v-on="$listeners"
  >
    <template #title>
      {{ i18n.title }}
    </template>

    <template #policy-profile-notice>
      {{
        s__(
          'DastProfiles|This scanner profile is currently being used by a policy. To make edits you must remove it from the active policy.',
        )
      }}
    </template>

    <template #error-message>{{ i18n.errorMessage }}</template>

    <gl-form-group data-testid="dast-scanner-parent-group" :disabled="isPolicyProfile">
      <gl-form-group :invalid-feedback="form.fields.profileName.feedback">
        <template #label>
          {{ s__('DastProfiles|Profile name') }}
          <tooltip-icon v-if="isProfileInUse" :title="i18n.tooltips.disabledProfileName" />
        </template>
        <gl-form-input
          v-model="form.fields.profileName.value"
          v-validation:[form.showValidation]
          :disabled="isProfileInUse"
          name="profileName"
          class="gl-max-w-62"
          data-testid="profile-name-input"
          type="text"
          required
          :state="form.fields.profileName.state"
        />
      </gl-form-group>

      <gl-form-group>
        <template #label>
          {{ s__('DastProfiles|Scan mode') }}
          <tooltip-icon :title="i18n.tooltips.scanMode" />
        </template>

        <gl-form-radio-group v-model="form.fields.scanType.value" data-testid="scan-type-option">
          <gl-form-radio
            v-for="option in $options.SCAN_TYPE_OPTIONS"
            :key="option.value"
            :value="option.value"
          >
            {{ option.text }}
            <template #help>
              {{ option.helpText }}
            </template>
          </gl-form-radio>
        </gl-form-radio-group>
      </gl-form-group>

      <div class="row">
        <gl-form-group
          class="gl-mb-0"
          :class="{ 'col-md-6': !stacked, 'col-md-12': stacked, 'gl-mb-4': stacked }"
          :invalid-feedback="form.fields.spiderTimeout.feedback"
          :state="form.fields.spiderTimeout.state"
        >
          <template #label>
            {{ s__('DastProfiles|Spider timeout') }}
            <tooltip-icon :title="i18n.tooltips.spiderTimeout" />
          </template>
          <gl-form-input-group
            v-model.number="form.fields.spiderTimeout.value"
            v-validation:[form.showValidation]
            name="spiderTimeout"
            class="gl-max-w-62"
            data-testid="spider-timeout-input"
            type="number"
            :min="$options.spiderTimeoutRange.min"
            :max="$options.spiderTimeoutRange.max"
            :state="form.fields.spiderTimeout.state"
            required
          >
            <template #append>
              <gl-input-group-text>{{ __('Minutes') }}</gl-input-group-text>
            </template>
          </gl-form-input-group>
          <div class="gl-text-gray-400 gl-my-2">
            {{ s__('DastProfiles|Minimum = 0 (no timeout enabled), Maximum = 2880 minutes') }}
          </div>
        </gl-form-group>

        <gl-form-group
          class="gl-mb-0"
          :class="{ 'col-md-6': !stacked, 'col-md-12': stacked }"
          :invalid-feedback="form.fields.targetTimeout.feedback"
          :state="form.fields.targetTimeout.state"
        >
          <template #label>
            {{ s__('DastProfiles|Target timeout') }}
            <tooltip-icon :title="i18n.tooltips.targetTimeout" />
          </template>
          <gl-form-input-group
            v-model.number="form.fields.targetTimeout.value"
            v-validation:[form.showValidation]
            name="targetTimeout"
            class="gl-max-w-62"
            data-testid="target-timeout-input"
            type="number"
            :min="$options.targetTimeoutRange.min"
            :max="$options.targetTimeoutRange.max"
            :state="form.fields.targetTimeout.state"
            required
          >
            <template #append>
              <gl-input-group-text>{{ __('Seconds') }}</gl-input-group-text>
            </template>
          </gl-form-input-group>
          <div class="gl-text-gray-400 gl-my-2">
            {{ s__('DastProfiles|Minimum = 1 second, Maximum = 3600 seconds') }}
          </div>
        </gl-form-group>
      </div>

      <div class="row gl-mt-5">
        <gl-form-group
          class="gl-mb-0"
          :class="{ 'col-md-6': !stacked, 'col-md-12': stacked, 'gl-mb-4': stacked }"
        >
          <template #label>
            {{ s__('DastProfiles|AJAX spider') }}
            <tooltip-icon :title="i18n.tooltips.ajaxSpider" />
          </template>
          <gl-form-checkbox v-model="form.fields.useAjaxSpider.value">{{
            s__('DastProfiles|Turn on AJAX spider')
          }}</gl-form-checkbox>
        </gl-form-group>

        <gl-form-group class="gl-mb-0" :class="{ 'col-md-6': !stacked, 'col-md-12': stacked }">
          <template #label>
            {{ s__('DastProfiles|Debug messages') }}
            <tooltip-icon :title="i18n.tooltips.debugMessage" />
          </template>
          <gl-form-checkbox v-model="form.fields.showDebugMessages.value">{{
            s__('DastProfiles|Show debug messages')
          }}</gl-form-checkbox>
        </gl-form-group>
      </div>
    </gl-form-group>
  </base-dast-profile-form>
</template>
