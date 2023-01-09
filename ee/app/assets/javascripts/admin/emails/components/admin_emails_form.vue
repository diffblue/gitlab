<script>
import { GlForm, GlFormGroup, GlFormInput, GlFormTextarea, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import validation, { initForm } from '~/vue_shared/directives/validation';
import csrf from '~/lib/utils/csrf';

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
  },
};

export default {
  components: { GlForm, GlFormGroup, GlFormInput, GlFormTextarea, GlButton },
  directives: {
    validation: validation(feedbackMap),
  },
  csrf,
  inject: ['adminEmailPath', 'adminEmailsAreCurrentlyRateLimited'],
  fields: {
    subject: {
      label: s__('AdminEmail|Subject'),
      validationMessage: s__('AdminEmail|Subject is required.'),
      key: 'subject',
    },
    body: {
      label: s__('AdminEmail|Body'),
      validationMessage: s__('AdminEmail|Body is required.'),
      key: 'body',
    },
  },
  i18n: {
    submitButton: __('Send message'),
  },
  data() {
    const form = initForm({
      fields: {
        subject: {
          value: '',
        },
        body: {
          value: '',
        },
      },
    });

    return {
      form,
    };
  },
  methods: {
    async handleSubmit(event) {
      this.form.showValidation = true;

      if (!this.form.state) {
        event.preventDefault();

        return;
      }

      this.form.showValidation = false;
    },
  },
};
</script>

<template>
  <gl-form
    class="gl-lg-form-input-xl"
    novalidate
    :action="adminEmailPath"
    method="post"
    @submit="handleSubmit"
  >
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    <gl-form-group
      :label="$options.fields.subject.label"
      :label-for="$options.fields.subject.key"
      :state="form.fields.subject.state"
      :invalid-feedback="form.fields.subject.feedback"
    >
      <gl-form-input
        :id="$options.fields.subject.key"
        v-model="form.fields.subject.value"
        v-validation:[form.showValidation]
        :validation-message="$options.fields.subject.validationMessage"
        :state="form.fields.subject.state"
        :name="$options.fields.subject.key"
        required
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.fields.body.label"
      :label-for="$options.fields.body.key"
      :state="form.fields.body.state"
      :invalid-feedback="form.fields.body.feedback"
    >
      <gl-form-textarea
        :id="$options.fields.body.key"
        v-model="form.fields.body.value"
        v-validation:[form.showValidation]
        :validation-message="$options.fields.body.validationMessage"
        :state="form.fields.body.state"
        :name="$options.fields.body.key"
        required
      />
    </gl-form-group>
    <gl-button
      class="js-no-auto-disable"
      type="submit"
      :disabled="adminEmailsAreCurrentlyRateLimited"
      category="primary"
      variant="confirm"
      >{{ $options.i18n.submitButton }}</gl-button
    >
  </gl-form>
</template>
