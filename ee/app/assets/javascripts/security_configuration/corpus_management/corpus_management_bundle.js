import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CorpusManagement from './components/corpus_management.vue';
import resolvers from './graphql/resolvers/resolvers';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('.js-corpus-management');

  if (!el) {
    return undefined;
  }

  const defaultClient = createDefaultClient(resolvers, {
    cacheConfig: {
      dataIdFromObject: (object) => {
        return object.id || defaultDataIdFromObject(object);
      },
    },
  });

  const {
    dataset: { projectFullPath },
  } = el;

  let {
    dataset: { corpusHelpPath },
  } = el;

  // TODO: This is fake data for a POC and will be removed as part of https://gitlab.com/groups/gitlab-org/-/epics/5017
  corpusHelpPath = 'https://docs.gitlab.com/ee/user/application_security/coverage_fuzzing/';

  const provide = {
    projectFullPath,
    corpusHelpPath,
  };

  return new Vue({
    el,
    provide,
    apolloProvider: new VueApollo({ defaultClient }),
    render(h) {
      return h(CorpusManagement, {});
    },
  });
};
