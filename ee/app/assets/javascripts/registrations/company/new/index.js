import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import RegistrationForm from 'ee/registrations/components/company_form.vue';

export default () => {
  const el = document.querySelector('#js-company-registration-form');

  const { submitPath, trial, role, jtbd, comment } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      submitPath,
      role,
      jtbd,
      comment,
    },
    render(createElement) {
      return createElement(RegistrationForm, {
        props: { trial },
      });
    },
  });
};
