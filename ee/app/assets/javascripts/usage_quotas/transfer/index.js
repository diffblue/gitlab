import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import GroupTransferApp from './components/group_transfer_app.vue';

export const initGroupTransferApp = () => {
  const el = document.getElementById('js-group-transfer-app');

  if (!el) return false;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { fullPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(GroupTransferApp);
    },
  });
};
