import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';
import createDefaultClient from '~/lib/graphql';

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (containerId = 'js-code-suggestions-usage-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { fullPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    name: 'CodeSuggestionsUsageApp',
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(CodeSuggestionsUsage);
    },
  });
};
