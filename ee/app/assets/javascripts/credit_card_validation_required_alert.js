import Vue from 'vue';
import CreditCardValidationRequiredAlert from 'ee/billings/components/cc_validation_required_alert.vue';

export default (containerId = 'js-cc-validation-required-alert') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(CreditCardValidationRequiredAlert, {
        props: {
          isFromAccountValidationEmail: 'openValidateAccountModal' in el.dataset,
        },
      });
    },
  });
};
