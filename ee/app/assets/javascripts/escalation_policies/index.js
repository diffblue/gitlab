import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import EscalationPoliciesWrapper from './components/escalation_policies_wrapper.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        dataIdFromObject: (object) => {
          // eslint-disable-next-line no-underscore-dangle
          if (object.__typename === 'IncidentManagementOncallSchedule') {
            return object.iid;
          }
          return defaultDataIdFromObject(object);
        },
      },
    },
  ),
});

export default () => {
  const el = document.querySelector('.js-escalation-policies');

  if (!el) return null;

  const { emptyEscalationPoliciesSvgPath, projectPath = '' } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      emptyEscalationPoliciesSvgPath,
    },
    render(createElement) {
      return createElement(EscalationPoliciesWrapper);
    },
  });
};
