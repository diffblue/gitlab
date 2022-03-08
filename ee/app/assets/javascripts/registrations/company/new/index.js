import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import RegistrationForm from '../components/registration_form.vue';

export default () => {
  const el = document.querySelector('#js-company-registration-form');

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(RegistrationForm);
    },
  });
};
