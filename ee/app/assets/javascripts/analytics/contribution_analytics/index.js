import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ContributionAnalyticsApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (el) => {
  const { fullPath, startDate, endDate } = el.dataset;
  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(ContributionAnalyticsApp, {
        props: { fullPath, startDate, endDate },
      });
    },
  });
};
