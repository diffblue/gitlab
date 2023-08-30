import Vue from 'vue';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';

export default (containerId = 'js-code-suggestions-usage-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'CodeSuggestionsUsageApp',
    render(createElement) {
      return createElement(CodeSuggestionsUsage);
    },
  });
};
