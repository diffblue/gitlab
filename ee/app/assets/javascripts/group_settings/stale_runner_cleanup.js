import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import StaleRunnerCleanupToggle from './components/stale_runner_cleanup_toggle.vue';

Vue.use(VueApollo);

export default (containerSelector = '#stale-runner-cleanup-form') => {
  const containerEl = document.querySelector(containerSelector);

  if (!containerEl) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { groupFullPath, staleTimeoutSecs } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    render(createElement) {
      return createElement(StaleRunnerCleanupToggle, {
        props: {
          groupFullPath,
          staleTimeoutSecs: parseInt(staleTimeoutSecs, 10),
        },
      });
    },
  });
};
