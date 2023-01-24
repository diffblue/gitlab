import Vue from 'vue';
import Api from '~/api';
import { s__ } from '~/locale';
import IndexingRestrictions from './components/indexing_restrictions.vue';

const initIndexingRestrictionsFactory = (
  selector,
  { appName, inputName, apiPath, selectorToggleText, nameProp, emptyListText },
) => {
  const el = document.querySelector(selector);

  if (process.env.NODE_ENV !== 'production' && el === null) {
    // eslint-disable-next-line no-console
    console.warn(`Tried to init indexing restrictions app but '${selector}' not found.`);
    return false;
  }

  return new Vue({
    el,
    name: appName,
    render(createElement) {
      return createElement(IndexingRestrictions, {
        props: {
          inputName,
          apiPath,
          selectorToggleText,
          nameProp,
          emptyListText,
          initialSelection: JSON.parse(el.dataset.selected),
        },
      });
    },
  });
};

export const initNamespacesIndexingRestrictions = () =>
  initIndexingRestrictionsFactory('.js-namespaces-indexing-restrictions', {
    appName: 'IndexingNamespacesRestrictionsRoot',
    inputName: 'application_setting[elasticsearch_namespace_ids]',
    apiPath: Api.buildUrl(Api.namespacesPath),
    selectorToggleText: s__('AdvancedSearch|Select namespaces to index'),
    nameProp: 'full_path',
    emptyListText: s__('AdvancedSearch|None. Select namespaces to index.'),
  });

export const initProjectsIndexingRestrictions = () =>
  initIndexingRestrictionsFactory('.js-projects-indexing-restrictions', {
    appName: 'IndexingProjectsRestrictionsRoot',
    inputName: 'application_setting[elasticsearch_project_ids]',
    apiPath: Api.buildUrl(Api.projectsPath),
    selectorToggleText: s__('AdvancedSearch|Select projects to index'),
    nameProp: 'name_with_namespace',
    emptyListText: s__('AdvancedSearch|None. Select projects to index.'),
  });
