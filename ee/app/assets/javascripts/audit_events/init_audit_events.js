import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { MAX_HEADERS } from './constants';
import AuditEventsApp from './components/audit_events_app.vue';
import createStore from './store';

Vue.use(VueApollo);

export default (selector) => {
  const el = document.querySelector(selector);
  const {
    events,
    isLastPage,
    filterTokenOptions,
    exportUrl = '',
    showFilter,
    showStreams,
    showStreamsHeaders,
    groupPath,
    emptyStateSvgPath,
    streamsIconSvgPath,
  } = el.dataset;
  const store = createStore();
  const parsedFilterTokenOptions = JSON.parse(filterTokenOptions).map((filterTokenOption) =>
    convertObjectPropsToCamelCase(filterTokenOption),
  );
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  store.dispatch('initializeAuditEvents');

  return new Vue({
    el,
    store,
    provide: {
      events: JSON.parse(events) || [],
      isLastPage: parseBoolean(isLastPage) || false,
      filterTokenOptions: parsedFilterTokenOptions,
      exportUrl,
      showFilter: parseBoolean(showFilter) || true,
      showStreams: parseBoolean(showStreams) || false,
      showStreamsHeaders: parseBoolean(showStreamsHeaders) || false,
      maxHeaders: MAX_HEADERS,
      groupPath,
      // group level and project level are mutually exclusive.
      isProject: !groupPath,
      emptyStateSvgPath,
      streamsIconSvgPath,
    },
    apolloProvider,
    render: (createElement) => createElement(AuditEventsApp),
  });
};
