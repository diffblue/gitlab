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

  const {
    fullPath,
    firstName,
    lastName,
    companyName,
    namespaceId,
    buttonAttributes,
    createHandRaiseLeadPath,
    glmContent,
    productInteraction,
    trackAction,
    trackLabel,
    userName,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    name: 'CodeSuggestionsUsageApp',
    provide: {
      fullPath,
      createHandRaiseLeadPath,
      buttonAttributes: buttonAttributes && { ...JSON.parse(buttonAttributes), variant: 'confirm' },
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
        productInteraction,
      },
      ctaTracking: {
        action: trackAction,
        label: trackLabel,
      },
    },
    render(createElement) {
      return createElement(CodeSuggestionsUsage);
    },
  });
};
