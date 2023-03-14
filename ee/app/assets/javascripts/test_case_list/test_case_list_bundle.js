import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { STATUS_OPEN } from '~/issues/constants';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';

import TestCaseListApp from './components/test_case_list_root.vue';

Vue.use(VueApollo);

const initTestCaseList = ({ mountPointSelector }) => {
  const mountPointEl = document.querySelector(mountPointSelector);

  if (!mountPointEl) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    canCreateTestCase,
    hasScopedLabelsFeature,
    page = 1,
    prev = '',
    next = '',
    initialState = STATUS_OPEN,
    initialSortBy = 'created_desc',
  } = mountPointEl.dataset;

  const initialFilterParams = Object.assign(
    convertObjectPropsToCamelCase(
      queryToObject(window.location.search.substring(1), { gatherArrays: true }),
      {
        dropKeys: ['scope', 'utf8', 'state', 'sort'], // These keys are unsupported/unnecessary
      },
    ),
  );

  return new Vue({
    el: mountPointEl,
    apolloProvider,
    provide: {
      ...mountPointEl.dataset,
      canCreateTestCase: parseBoolean(canCreateTestCase),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      page: parseInt(page, 10),
      prev,
      next,
      initialState,
      initialSortBy,
    },
    render: (createElement) =>
      createElement(TestCaseListApp, {
        props: {
          initialFilterParams,
        },
      }),
  });
};

export default initTestCaseList;
