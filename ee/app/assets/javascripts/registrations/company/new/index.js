import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import CompanyForm from 'ee/registrations/components/company_form.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const el = document.querySelector('#js-registrations-company-form');
  const { submitPath, automaticTrial } = el.dataset;
  const trial = Boolean(new URLSearchParams(window.location.search).get('trial'));

  return new Vue({
    el,
    apolloProvider,
    provide: {
      submitPath,
    },
    render(createElement) {
      return createElement(CompanyForm, {
        props: { trial, automaticTrial: parseBoolean(automaticTrial) },
      });
    },
  });
};
