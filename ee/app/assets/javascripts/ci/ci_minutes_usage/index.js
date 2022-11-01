import Vue from 'vue';

import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CiMinutesUsageApp from './components/app.vue';

const mountCiMinutesUsageApp = (el) => {
  Vue.use(VueApollo);

  const defaultClient = createDefaultClient();
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'CiMinutesUsageApp',
    components: {
      CiMinutesUsageApp,
    },
    render: (createElement) => createElement(CiMinutesUsageApp, {}),
  });
};

export default () => {
  const el = document.querySelector('.js-ci-minutes-usage');
  return !el ? {} : mountCiMinutesUsageApp(el);
};
