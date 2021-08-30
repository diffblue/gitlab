import Vue from 'vue';
import ensureData from '~/ensure_data';
import apolloProvider from '../buy_addons_shared/graphql';
import { writeInitialDataToApolloCache } from '../buy_addons_shared/utils';
import App from './components/app.vue';

export default (el) => {
  if (!el) {
    return null;
  }

  const extendedApp = ensureData(App, {
    parseData: writeInitialDataToApolloCache.bind(null, apolloProvider),
    data: el.dataset,
    shouldLog: true,
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(extendedApp);
    },
  });
};
