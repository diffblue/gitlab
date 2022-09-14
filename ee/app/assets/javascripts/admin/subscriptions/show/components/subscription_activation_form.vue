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
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import {
  activateLabel,
  INVALID_CODE_ERROR,
  INVALID_ACTIVATION_CODE_SERVER_ERROR,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
  SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT,
  subscriptionActivationForm,
} from '../constants';
import { getErrorsAsData, getLicenseFromData } from '../utils';
import activateSubscriptionMutation from '../graphql/mutations/activate_subscription.mutation.graphql';

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
  },
  patternMismatch: {
    isInvalid: (el) => el.validity?.patternMismatch,
  },
};

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
    activationCodeFeedback: subscriptionActivationForm.activationCodeFeedback,
    activateLabel,
    activationCode: subscriptionActivationForm.activationCode,
    acceptTermsFeedback: subscriptionActivationForm.acceptTermsFeedback,
    pasteActivationCode: subscriptionActivationForm.pasteActivationCode,
  },
  directives: {
    validation: validation(feedbackMap),
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
      termsLink: `${PROMO_URL}/terms/`,
    };
  },
  computed: {
    checkboxLabelClass() {
      // by default, if the value is not false the text will look green, therefore we force it to gray-900
      return this.form.fields.terms.state === false ? '' : 'gl-text-gray-900!';
    },
  },
  methods: {
    handleError(error) {
      this.$emit(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT, error.message);
    },
    submit() {
      if (!this.form.state) {
        this.form.showValidation = true;
        this.$emit(SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT);
        return;
      }
      this.form.showValidation = false;
      this.isLoading = true;
      this.$apollo
        .mutate({
          mutation: activateSubscriptionMutation,
          variables: {
            gitlabSubscriptionActivateInput: {
              activationCode: this.form.fields.activationCode.value,
            },
          },
          update: (cache, res) => {
            const errors = getErrorsAsData(res);
            if (errors.length) {
              const [error] = errors;
              if (error.includes(INVALID_ACTIVATION_CODE_SERVER_ERROR)) {
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
          },
        })
        .catch((error) => {
          this.handleError(error);
        })
        .finally(() => {
          this.$emit(SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT);
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <gl-form novalidate @submit.prevent="submit">
    <div class="gl-display-flex gl-flex-wrap">
      <gl-form-group
        class="gl-flex-grow-1"
        :invalid-feedback="form.fields.activationCode.feedback"
        :state="form.fields.activationCode.state"
        data-testid="form-group-activation-code"
      >
        <label class="gl-w-full" for="activation-code-group">
          {{ $options.i18n.activationCode }}
        </label>
        <gl-form-input
          id="activation-code-group"
          v-model.trim="form.fields.activationCode.value"
          v-validation:[form.showValidation]
          class="gl-mb-4"
          data-qa-selector="activation_code"
          :disabled="isLoading"
          :placeholder="$options.i18n.pasteActivationCode"
          :state="form.fields.activationCode.state"
          :validation-message="$options.i18n.activationCodeFeedback"
          name="activationCode"
          pattern="\w{24}"
          required
        />
      </gl-form-group>

      <gl-form-group
        class="gl-mb-0"
        :invalid-feedback="form.fields.terms.feedback"
        :state="form.fields.terms.state"
        data-testid="form-group-terms"
      >
        <gl-form-checkbox
          id="subscription-form-terms-check"
          v-model="form.fields.terms.value"
          v-validation:[form.showValidation]
          :state="form.fields.terms.state"
          :validation-message="$options.i18n.acceptTermsFeedback"
          name="terms"
          required
        >
          <span :class="checkboxLabelClass">
            <gl-sprintf :message="$options.i18n.acceptTerms">
              <template #link="{ content }">
                <gl-link :href="termsLink" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </gl-form-checkbox>
      </gl-form-group>

      <gl-button
        v-if="!hideSubmitButton"
        :loading="isLoading"
        category="primary"
        class="gl-mt-6 js-no-auto-disable"
        data-testid="activate-button"
        data-qa-selector="activate"
        type="submit"
        variant="confirm"
      >
        {{ $options.i18n.activateLabel }}
      </gl-button>
    </div>
  </gl-form>
</template>
