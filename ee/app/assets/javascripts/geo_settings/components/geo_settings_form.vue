<script>
import { GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__, __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { mapComputed } from '~/vuex_shared/bindings';
import { FORM_VALIDATION_FIELDS } from '../constants';
import { validateTimeout, validateAllowedIp } from '../validations';

export default {
  name: 'GeoSettingsForm',
  i18n: {
    timeoutFieldLabel: s__('Geo|Connection timeout'),
    timeoutFieldDescription: s__('Geo|Time in seconds'),
    allowedIpFieldLabel: s__('Geo|Allowed Geo IP'),
    allowedIpFieldDescription: s__("Geo|Comma-separated, e.g. '1.1.1.1, 2.2.2.0/24'"),
    saveChanges: __('Save changes'),
    cancel: __('Cancel'),
  },
  components: {
    GlFormGroup,
    GlFormInput,
    GlButton,
  },
  computed: {
    ...mapState(['formErrors', 'sitesPath']),
    ...mapGetters(['formHasError']),
    ...mapComputed([
      { key: 'timeout', updateFn: 'setTimeout' },
      { key: 'allowedIp', updateFn: 'setAllowedIp' },
    ]),
  },
  methods: {
    ...mapActions(['updateGeoSettings', 'setFormError']),
    redirect() {
      visitUrl(this.sitesPath);
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
      :label="$options.i18n.timeoutFieldLabel"
      label-for="settings-timeout-field"
      :description="$options.i18n.timeoutFieldDescription"
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
      :label="$options.i18n.allowedIpFieldLabel"
      label-for="settings-allowed-ip-field"
      :description="$options.i18n.allowedIpFieldDescription"
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
    <section class="gl-display-flex">
      <gl-button
        data-testid="settingsSaveButton"
        data-qa-selector="add_site_button"
        class="gl-mr-3"
        variant="confirm"
        :disabled="formHasError"
        @click="updateGeoSettings"
        >{{ $options.i18n.saveChanges }}</gl-button
      >
      <gl-button data-testid="settingsCancelButton" @click="redirect">{{
        $options.i18n.cancel
      }}</gl-button>
    </section>
  </form>
</template>
