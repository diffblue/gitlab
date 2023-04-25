import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (el) => {
  const { fullPath, startDate, endDate } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    name: 'ContributionAnalyticsRoot',
    render(createElement) {
      return createElement(App, {
        props: { fullPath, startDate, endDate },
      });
    },
  });
};
