<script>
import { GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import { mapComputed } from '~/vuex_shared/bindings';
import { FORM_VALIDATION_FIELDS } from '../constants';
import { validateTimeout, validateAllowedIp } from '../validations';

export default {
  name: 'GeoSettingsForm',
  components: {
    GlFormGroup,
    GlFormInput,
    GlButton,
  },
  computed: {
    ...mapState(['formErrors', 'nodesPath']),
    ...mapGetters(['formHasError']),
    ...mapComputed([
      { key: 'timeout', updateFn: 'setTimeout' },
      { key: 'allowedIp', updateFn: 'setAllowedIp' },
    ]),
  },
  methods: {
    ...mapActions(['updateGeoSettings', 'setFormError']),
    redirect() {
      visitUrl(this.nodesPath);
    },
    checkTimeout() {
      this.setFormError({
        key: FORM_VALIDATION_FIELDS.TIMEOUT,
        error: validateTimeout(this.timeout),
      });
    },
    checkAllowedIp() {
      this.setFormError({
        key: FORM_VALIDATION_FIELDS.ALLOWED_IP,
        error: validateAllowedIp(this.allowedIp),
      });
    },
  },
};
</script>

<template>
  <form>
    <gl-form-group
      :label="__('Connection timeout')"
      label-for="settings-timeout-field"
      :description="__('Time in seconds')"
      :state="Boolean(formErrors.timeout)"
      :invalid-feedback="formErrors.timeout"
    >
      <gl-form-input
        id="settings-timeout-field"
        v-model="timeout"
        class="col-sm-2"
        type="number"
        number
        :class="{ 'is-invalid': Boolean(formErrors.timeout) }"
        @blur="checkTimeout"
      />
    </gl-form-group>
    <gl-form-group
      :label="__('Allowed Geo IP')"
      label-for="settings-allowed-ip-field"
      :description="__('Comma-separated, e.g. \'1.1.1.1, 2.2.2.0/24\'')"
      :state="Boolean(formErrors.allowedIp)"
      :invalid-feedback="formErrors.allowedIp"
    >
      <gl-form-input
        id="settings-allowed-ip-field"
        v-model="allowedIp"
        class="col-sm-6"
        type="text"
        :class="{ 'is-invalid': Boolean(formErrors.allowedIp) }"
        @blur="checkAllowedIp"
      />
    </gl-form-group>
    <section
      class="gl-display-flex gl-align-items-center gl-p-5 gl-mt-6 gl-bg-gray-10 gl-border-t-solid gl-border-t-1 gl-border-gray-100"
    >
      <gl-button
        data-testid="settingsSaveButton"
        data-qa-selector="add_node_button"
        class="gl-mr-5"
        variant="info"
        :disabled="formHasError"
        @click="updateGeoSettings"
        >{{ __('Save changes') }}</gl-button
      >
      <gl-button data-testid="settingsCancelButton" @click="redirect">{{ __('Cancel') }}</gl-button>
    </section>
  </form>
</template>
