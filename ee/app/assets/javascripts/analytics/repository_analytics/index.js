import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import GroupRepositoryAnalytics from './components/group_repository_analytics.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-group-repository-analytics');
  const { groupAnalyticsCoverageReportsPath, groupFullPath } = el?.dataset || {};

  if (el) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        GroupRepositoryAnalytics,
      },
      apolloProvider,
      provide: {
        groupAnalyticsCoverageReportsPath,
        groupFullPath,
      },
      render(createElement) {
        return createElement('group-repository-analytics', {});
      },
    });
  }
};
