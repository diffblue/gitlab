import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions } from 'vuex';
import { setCookie, convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { parseIssuableData } from '~/issues/show/utils/parse_data';

import { defaultClient } from '~/graphql_shared/issuable_client';
import labelsSelectModule from '~/sidebar/components/labels/labels_select_vue/store';
import getIssueStateQuery from '~/issues/show/queries/get_issue_state.query.graphql';
import { TYPE_EPIC } from '~/issues/constants';

import EpicApp from './components/epic_app.vue';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient,
});

apolloProvider.clients.defaultClient.cache.writeQuery({
  query: getIssueStateQuery,
  data: {
    issueState: {
      isDirty: false,
      issuableType: TYPE_EPIC,
    },
  },
});

export default () => {
  const el = document.getElementById('epic-app-root');

  if (!el) {
    return false;
  }

  const store = createStore();
  store.registerModule('labelsSelect', labelsSelectModule());

  const epicMeta = convertObjectPropsToCamelCase(JSON.parse(el.dataset.meta), { deep: true });
  const epicData = parseIssuableData(el);

  const { treeElementSelector, roadmapElementSelector, containerElementSelector } = el.dataset;

  // Collapse the sidebar on mobile screens by default
  const bpBreakpoint = bp.getBreakpointSize();
  if (bpBreakpoint === 'xs' || bpBreakpoint === 'sm' || bpBreakpoint === 'md') {
    setCookie('collapsed_gutter', true);
  }

  return new Vue({
    el,
    name: 'EpicRoot',
    apolloProvider,
    store,
    components: { EpicApp },
    provide: {
      canUpdate: epicData.canUpdate,
      allowLabelCreate: parseBoolean(epicData.canUpdate),
      allowLabelEdit: parseBoolean(epicData.canUpdate),
      fullPath: epicData.fullPath,
      iid: epicMeta.epicIid,
      isClassicSidebar: true,
      allowScopedLabels: epicMeta.scopedLabels,
      labelsManagePath: epicMeta.labelsWebUrl,
      allowSubEpics: parseBoolean(el.dataset.allowSubEpics),
      treeElementSelector,
      roadmapElementSelector,
      containerElementSelector,
    },
    created() {
      this.setEpicMeta({
        ...epicMeta,
        allowSubEpics: parseBoolean(el.dataset.allowSubEpics),
      });
      this.setEpicData(epicData);
    },
    methods: {
      ...mapActions(['setEpicMeta', 'setEpicData']),
    },
    render: (createElement) => createElement('epic-app'),
  });
};
