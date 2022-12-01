import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  extractFilterQueryParameters,
  extractPaginationQueryParameters,
} from '~/analytics/shared/utils';
import { buildCycleAnalyticsInitialData } from '../shared/utils';
import CycleAnalytics from './components/base.vue';
import createStore from './store';

Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-cycle-analytics');
  const { emptyStateSvgPath, noDataSvgPath, noAccessSvgPath } = el.dataset;
  const initialData = buildCycleAnalyticsInitialData(el.dataset);
  const store = createStore();

  const pagination = extractPaginationQueryParameters(window.location.search);
  const {
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
  } = extractFilterQueryParameters(window.location.search);

  store.dispatch('initializeCycleAnalytics', {
    ...initialData,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    pagination,
  });

  return new Vue({
    el,
    name: 'CycleAnalyticsApp',
    apolloProvider,
    store,
    render: (createElement) =>
      createElement(CycleAnalytics, {
        props: {
          emptyStateSvgPath,
          noDataSvgPath,
          noAccessSvgPath,
        },
      }),
  });
};
