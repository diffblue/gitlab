import Vue from 'vue';

import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CiMinutesUsageAppGroup from './components/app.vue';

const mountCiMinutesUsageAppGroup = (el) => {
  const { namespaceId } = el.dataset;

  Vue.use(VueApollo);

  const defaultClient = createDefaultClient();
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'CiMinutesUsageAppGroup',
    components: {
      CiMinutesUsageAppGroup,
    },
    provide: {
      namespaceId,
    },
    render: (createElement) => createElement(CiMinutesUsageAppGroup),
  });
};

export default () => {
  const el = document.getElementById('js-ci-minutes-usage-group');
  return !el ? {} : mountCiMinutesUsageAppGroup(el);
};
