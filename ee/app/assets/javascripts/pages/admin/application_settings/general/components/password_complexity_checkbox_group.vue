<script>
import { GlFormGroup } from '@gitlab/ui';
import SignupCheckbox from '~/pages/admin/application_settings/general/components/signup_checkbox.vue';
import { I18N } from '../constants';

export default {
  components: {
    GlFormGroup,
    SignupCheckbox,
  },
  inject: [
    'passwordNumberRequired',
    'passwordLowercaseRequired',
    'passwordUppercaseRequired',
    'passwordSymbolRequired',
  ],
  data() {
    const {
      passwordNumberRequired,
      passwordLowercaseRequired,
      passwordUppercaseRequired,
      passwordSymbolRequired,
    } = this;
    return {
      form: {
        passwordNumberRequired,
        passwordLowercaseRequired,
        passwordUppercaseRequired,
        passwordSymbolRequired,
      },
    };
  },
  methods: {
    changePasswordComplexitySetting(propName, value) {
      this.form[propName] = value;
      this.$emit('set-password-complexity', { name: propName, value });
    },
  },
  i18n: I18N,
};
</script>

<template>
  <gl-form-group>
    <signup-checkbox
      :value="form.passwordNumberRequired"
      :label="$options.i18n.passwordNumberRequiredLabel"
      :help-text="$options.i18n.passwordNumberRequiredHelpText"
      name="application_setting[password_number_required]"
      data-testid="password-number-required-checkbox"
      @input="changePasswordComplexitySetting('passwordNumberRequired', $event)"
    />
    <signup-checkbox
      :value="form.passwordUppercaseRequired"
      :label="$options.i18n.passwordUppercaseRequiredLabel"
      :help-text="$options.i18n.passwordUppercaseRequiredHelpText"
      name="application_setting[password_uppercase_required]"
      data-testid="password-uppercase-required-checkbox"
      @input="changePasswordComplexitySetting('passwordUppercaseRequired', $event)"
    />
    <signup-checkbox
      :value="form.passwordLowercaseRequired"
      :label="$options.i18n.passwordLowercaseRequiredLabel"
      :help-text="$options.i18n.passwordLowercaseRequiredHelpText"
      name="application_setting[password_lowercase_required]"
      data-testid="password-lowercase-required-checkbox"
      @input="changePasswordComplexitySetting('passwordLowercaseRequired', $event)"
    />
    <signup-checkbox
      :value="form.passwordSymbolRequired"
      :label="$options.i18n.passwordSymbolRequiredLabel"
      :help-text="$options.i18n.passwordSymbolRequiredHelpText"
      name="application_setting[password_symbol_required]"
      data-testid="password-symbol-required-checkbox"
      @input="changePasswordComplexitySetting('passwordSymbolRequired', $event)"
    />
  </gl-form-group>
</template>
