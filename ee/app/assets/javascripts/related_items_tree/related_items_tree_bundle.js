import Vue from 'vue';
import Vuex from 'vuex';

import { parseBoolean } from '~/lib/utils/common_utils';

import RelatedItemsTreeApp from './components/related_items_tree_app.vue';
import TreeItem from './components/tree_item.vue';
import TreeRoot from './components/tree_root.vue';
import createStore from './store';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-tree');

  if (!el) {
    return false;
  }

  const {
    id,
    iid,
    numericalId,
    fullPath,
    groupId,
    groupName,
    autoCompleteEpics,
    autoCompleteIssues,
    userSignedIn,
    allowIssuableHealthStatus,
    allowScopedLabels,
    allowSubEpics,
    type,
  } = el.dataset;
  const initialData = JSON.parse(el.dataset.initial);
  const roadmapAppData = JSON.parse(el.dataset.roadmapAppData);

  Vue.component('TreeRoot', TreeRoot);
  Vue.component('TreeItem', TreeItem);

  return new Vue({
    el,
    name: 'RelatedItemsTreeRoot',
    store: createStore(),
    components: { RelatedItemsTreeApp },
    provide: {
      roadmapAppData,
    },
    created() {
      this.setInitialParentItem({
        fullPath,
        type,
        numericalId: parseInt(numericalId, 10),
        groupId: parseInt(groupId, 10),
        groupName,
        id,
        iid: parseInt(iid, 10),
        title: initialData.initialTitleText,
        confidential: initialData.confidential,
        reference: `${initialData.fullPath}${initialData.issuableRef}`,
        userPermissions: {
          canAdmin: initialData.canAdmin,
          canAdminRelation: initialData.canAdminRelation,
        },
      });

      this.setInitialConfig({
        epicsEndpoint: initialData.epicLinksEndpoint,
        issuesEndpoint: initialData.issueLinksEndpoint,
        projectsEndpoint: initialData.projectsEndpoint,
        autoCompleteEpics: parseBoolean(autoCompleteEpics),
        autoCompleteIssues: parseBoolean(autoCompleteIssues),
        userSignedIn: parseBoolean(userSignedIn),
        allowIssuableHealthStatus: parseBoolean(allowIssuableHealthStatus),
        allowScopedLabels: parseBoolean(allowScopedLabels),
        allowSubEpics: parseBoolean(allowSubEpics),
        epicsWebUrl: initialData.epicsWebUrl,
        issuesWebUrl: initialData.issuesWebUrl,
      });
    },
    methods: {
      ...Vuex.mapActions(['setInitialParentItem', 'setInitialConfig']),
    },
    render: (createElement) => createElement('related-items-tree-app'),
  });
};
