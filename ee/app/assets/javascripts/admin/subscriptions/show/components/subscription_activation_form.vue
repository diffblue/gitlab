<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import validation from '~/vue_shared/directives/validation';
import {
  activateLabel,
  INVALID_CODE_ERROR,
  INVALID_CODE_ERROR_MESSAGE,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
  subscriptionActivationForm,
  subscriptionQueries,
} from '../constants';
import { getErrorsAsData, getLicenseFromData, updateSubscriptionAppCache } from '../graphql/utils';

export default {
  name: 'SubscriptionActivationForm',
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlSprintf,
    GlLink,
  },
  i18n: {
    acceptTerms: subscriptionActivationForm.acceptTerms,
    activateLabel,
    activationCode: subscriptionActivationForm.activationCode,
    pasteActivationCode: subscriptionActivationForm.pasteActivationCode,
  },
  directives: {
    validation: validation(),
  },
  props: {
    hideSubmitButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        activationCode: {
          required: true,
          state: null,
          value: '',
        },
        terms: {
          required: true,
          state: null,
          value: null,
        },
      },
    };
    return {
      form,
      isLoading: false,
    };
  },
  computed: {
    checkboxLabelClass() {
      // by default, if the value is not false the text will look green, therefore we force it to gray-900
      return this.form.fields.terms.state === false ? '' : 'gl-text-gray-900!';
    },
    isRequestingActivation() {
      return this.isLoading;
    },
  },
  methods: {
    handleError(error) {
      this.$emit(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT, error.message);
    },
    submit() {
      if (!this.form.state) {
        this.form.showValidation = true;
        return;
      }
      this.form.showValidation = false;
      this.isLoading = true;
      this.$apollo
        .mutate({
          mutation: subscriptionQueries.mutation,
          variables: {
            gitlabSubscriptionActivateInput: {
              activationCode: this.form.fields.activationCode.value,
            },
          },
          update: (cache, res) => {
            const errors = getErrorsAsData(res);
            if (errors.length) {
              const [error] = errors;
              if (error.includes(INVALID_CODE_ERROR_MESSAGE)) {
                this.handleError(new Error(INVALID_CODE_ERROR));
                return;
              }
              this.handleError(new Error(error));
              return;
            }
            const license = getLicenseFromData(res);
            if (license) {
              this.$emit(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT, license);
            }
            this.updateSubscriptionAppCache(cache, res);
          },
        })
        .catch((error) => {
          this.handleError(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    updateSubscriptionAppCache,
  },
};
</script>
<template>
  <gl-form novalidate @submit.prevent="submit">
    <div class="gl-display-flex gl-flex-wrap">
      <gl-form-group
        class="gl-flex-grow-1"
        :invalid-feedback="form.fields.activationCode.feedback"
        data-testid="form-group-activation-code"
      >
        <label class="gl-w-full" for="activation-code-group">
          {{ $options.i18n.activationCode }}
        </label>
        <gl-form-input
          id="activation-code-group"
          v-model.trim="form.fields.activationCode.value"
          v-validation:[form.showValidation]
          :disabled="isLoading"
          :placeholder="$options.i18n.pasteActivationCode"
          :state="form.fields.activationCode.state"
          name="activationCode"
          class="gl-mb-4"
          required
        />
      </gl-form-group>

      <gl-form-group class="gl-mb-0" data-testid="form-group-terms">
        <gl-form-checkbox
          id="subscription-form-terms-check"
          v-model="form.fields.terms.value"
          v-validation:[form.showValidation]
          :state="form.fields.terms.state"
          name="terms"
          required
        >
          <span :class="checkboxLabelClass">
            <gl-sprintf :message="$options.i18n.acceptTerms">
              <template #link="{ content }">
                <gl-link href="https://about.gitlab.com/terms/" target="_blank">{{
                  content
                }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </gl-form-checkbox>
      </gl-form-group>

      <gl-button
        v-if="!hideSubmitButton"
        :loading="isRequestingActivation"
        category="primary"
        class="gl-mt-6 js-no-auto-disable"
        data-testid="activate-button"
        type="submit"
        variant="confirm"
      >
        {{ $options.i18n.activateLabel }}
      </gl-button>
    </div>
  </gl-form>
</template>
