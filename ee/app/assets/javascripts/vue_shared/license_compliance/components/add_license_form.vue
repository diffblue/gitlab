<script>
import { GlButton, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { LICENSE_APPROVAL_STATUS } from '../constants';
import AddLicenseFormDropdown from './add_license_form_dropdown.vue';

export default {
  name: 'AddLicenseForm',
  components: {
    AddLicenseFormDropdown,
    GlButton,
    GlFormRadioGroup,
    GlFormRadio,
  },
  mixins: [glFeatureFlagsMixin()],
  LICENSE_APPROVAL_STATUS,
  approvalStatusOptions: [
    {
      value: LICENSE_APPROVAL_STATUS.ALLOWED,
      label: s__('LicenseCompliance|Allow'),
      description: s__('LicenseCompliance|Acceptable license to be used in the project'),
    },
    {
      value: LICENSE_APPROVAL_STATUS.DENIED,
      label: s__('LicenseCompliance|Deny'),
      description: s__(
        'LicenseCompliance|Disallow merge request if detected and will instruct developer to remove',
      ),
    },
  ],
  props: {
    managedLicenses: {
      type: Array,
      required: false,
      default: () => [],
    },
    knownLicenses: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      approvalStatus: '',
      licenseName: '',
    };
  },
  computed: {
    isInvalidLicense() {
      return this.managedLicenses.some(({ name }) => name === this.licenseName);
    },
    submitDisabled() {
      return this.isInvalidLicense || this.licenseName.trim() === '' || this.approvalStatus === '';
    },
  },
  methods: {
    addLicense() {
      this.$emit('addLicense', {
        newStatus: this.approvalStatus,
        license: { name: this.licenseName },
      });
    },
    closeForm() {
      this.$emit('closeForm');
    },
    handleLicenseUpdate(license) {
      this.licenseName = license;
    },
  },
};
</script>
<template>
  <div class="col-sm-6 js-add-license-form">
    <div class="form-group">
      <add-license-form-dropdown
        :known-licenses="knownLicenses"
        @update-selected-license="handleLicenseUpdate"
      />
      <div class="invalid-feedback" :class="{ 'd-block': isInvalidLicense }">
        {{ s__('LicenseCompliance|This license already exists in this project.') }}
      </div>
    </div>
    <div class="form-group">
      <gl-form-radio-group v-model="approvalStatus" name="approvalStatus">
        <gl-form-radio
          v-for="option in $options.approvalStatusOptions"
          :key="option.value"
          :value="option.value"
          :data-qa-selector="`${option.value}_license_radio`"
          :aria-describedby="`js-${option.value}-license-radio`"
          class="gl-mb-3"
        >
          {{ option.label }}
          <div class="text-secondary">
            {{ option.description }}
          </div>
        </gl-form-radio>
      </gl-form-radio-group>
    </div>
    <div class="gl-display-flex">
      <gl-button
        class="js-submit"
        :disabled="submitDisabled"
        :loading="loading"
        variant="confirm"
        data-qa-selector="add_license_submit_button"
        @click="addLicense"
      >
        {{ __('Submit') }}
      </gl-button>
      <gl-button class="js-cancel ml-2" :disabled="loading" @click="closeForm">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
