import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import CompanyForm from 'ee/registrations/components/company_form.vue';
import { __ } from '~/locale';

export default () => {
  const el = document.querySelector('#js-registrations-company-form');

  let { submitPath } = el.dataset;

  const params = new URLSearchParams(window.location.search);
  const trial = Boolean(params.get('trial'));
  submitPath = submitPath.replace(__('trial=true'), '');

  return new Vue({
    el,
    apolloProvider,
    provide: {
      submitPath,
    },
    render(createElement) {
      return createElement(CompanyForm, {
        props: { trial },
      });
    },
  });
};
