<script>
import { GlFormGroup, GlFormInput, GlFormCheckbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { initFormField } from 'ee/security_configuration/utils';
import { serializeFormObject } from '~/lib/utils/forms';
import validation from '~/vue_shared/directives/validation';
import { generateFormDastSiteFields } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
  },
  directives: {
    validation: validation(),
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    showValidation: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    stacked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isTargetApi: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    const {
      enabled = false,
      url,
      username,
      password,
      // default to commonly used names for `username` and `password` fields in authentcation forms
      usernameField = 'username',
      passwordField = 'password',
      submitField,
    } = this.value.fields;

    return {
      form: {
        state: false,
        fields: {
          enabled: initFormField({ value: enabled, skipValidation: true }),
          url: initFormField({ value: url, required: false, skipValidation: true }),
          username: initFormField({ value: username }),
          password: this.isEditMode
            ? initFormField({ value: password, required: false, skipValidation: true })
            : initFormField({ value: password }),
          usernameField: initFormField({
            value: usernameField,
            required: false,
            skipValidation: true,
          }),
          passwordField: initFormField({
            value: passwordField,
            required: false,
            skipValidation: true,
          }),
          submitField: initFormField({ value: submitField, required: false, skipValidation: true }),
        },
      },
      isSensitiveFieldRequired: !this.isEditMode,
    };
  },
  computed: {
    formFields() {
      return generateFormDastSiteFields(this.isSensitiveFieldRequired, this.showBasicAuthOption);
    },
    showBasicAuthOption() {
      return this.isTargetApi;
    },
    i18n() {
      return {
        enableAuth: this.showBasicAuthOption
          ? s__('DastProfiles|Enable Basic Authentication')
          : s__('DastProfiles|Enable Authentication'),
      };
    },
  },
  watch: {
    form: { handler: 'emitUpdate', immediate: true, deep: true },
  },
  created() {
    this.emitUpdate();
  },
  methods: {
    emitUpdate() {
      this.$emit('input', {
        fields: serializeFormObject(this.form.fields),
        state: this.form.state,
      });
    },
  },
};
</script>

<template>
  <section>
    <gl-form-group class="gl-mb-0" data-testid="dast-site-auth-parent-group" :disabled="disabled">
      <gl-form-group :label="s__('DastProfiles|Authentication')">
        <gl-form-checkbox v-model="form.fields.enabled.value" data-testid="auth-enable-checkbox">{{
          i18n.enableAuth
        }}</gl-form-checkbox>
      </gl-form-group>
      <div v-if="form.fields.enabled.value" data-testid="auth-form">
        <div class="row">
          <div
            v-for="option in formFields"
            :key="option.fieldName"
            class="col-md-6"
            :class="{ 'col-md-12': stacked, 'gl-lg-mr-10': option.newLine && !stacked }"
          >
            <gl-form-group
              v-if="!option.showBasicAuthOption"
              :label="option.label"
              :invalid-feedback="form.fields[option.fieldName].feedback"
            >
              <gl-form-input
                v-model="form.fields[option.fieldName].value"
                v-validation:[showValidation]
                :autocomplete="option.autocomplete"
                :name="option.fieldName"
                :type="option.type"
                :required="option.isRequired"
                :state="form.fields[option.fieldName].state"
              />
            </gl-form-group>
          </div>
        </div>
      </div>
    </gl-form-group>
  </section>
</template>
