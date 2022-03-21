import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import RegistrationForm from 'ee/registrations/components/company_form.vue';

export default () => {
  const el = document.querySelector('#js-company-registration-form');

  const { trial, createLeadPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: { createLeadPath },
    render(createElement) {
      return createElement(RegistrationForm, {
        props: { trial },
      });
    },
  });
};
