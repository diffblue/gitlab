import { defaultDataIdFromObject } from '@apollo/client/core';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { helpPagePath } from '~/helpers/help_page_helper';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
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
    dataset: {
      emptyStateSvgPath,
      projectFullPath,
      canUploadCorpus,
      canReadCorpus,
      canDestroyCorpus,
    },
  } = el;

  const corpusHelpPath = helpPagePath('user/application_security/coverage_fuzzing/index', {
    anchor: 'corpus-registry',
  });

  const provide = {
    emptyStateSvgPath,
    projectFullPath,
    corpusHelpPath,
    canUploadCorpus: parseBoolean(canUploadCorpus),
    canReadCorpus: parseBoolean(canReadCorpus),
    canDestroyCorpus: parseBoolean(canDestroyCorpus),
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
