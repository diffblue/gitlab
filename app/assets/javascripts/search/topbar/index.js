import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GlobalSearchTopbar from './components/app.vue';

Vue.use(Translate);

export const initTopbar = (store) => {
  const el = document.getElementById('js-search-topbar');

  if (!el) {
    return false;
  }

  const {
    groupInitialData,
    projectInitialData,
    advancedSearchData,
    defaultBranchData,
  } = el.dataset;

  const groupInitialDataParsed = JSON.parse(groupInitialData);
  const projectInitialDataParsed = JSON.parse(projectInitialData);
  const advancedSearchDataParsed = JSON.parse(advancedSearchData);

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GlobalSearchTopbar, {
        props: {
          groupInitialData: groupInitialDataParsed,
          projectInitialData: projectInitialDataParsed,
          advancedSearchData: advancedSearchDataParsed,
          defaultBranchData,
        },
      });
    },
  });
};
