import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import SharedRunnerUsage from 'ee/analytics/group_ci_cd_analytics/components/shared_runner_usage.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-shared-runner-usage-quota');

  if (!el) return false;

  const { namespaceId } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      groupId: namespaceId,
    },
    render: (createElement) => createElement(SharedRunnerUsage),
  });
};
