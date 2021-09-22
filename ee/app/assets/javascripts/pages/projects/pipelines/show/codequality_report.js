import Vue from 'vue';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import createStore from 'ee/codequality_report/store';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () => {
  const tabsElement = document.querySelector('.pipelines-tabs');
  const codequalityTab = document.getElementById('js-pipeline-codequality-report');

  if (tabsElement && codequalityTab) {
    const fetchReportAction = 'fetchReport';
    const {
      codequalityReportDownloadPath,
      blobPath,
      projectPath,
      pipelineIid,
    } = codequalityTab.dataset;
    const store = createStore({
      endpoint: codequalityReportDownloadPath,
      blobPath,
      projectPath,
      pipelineIid,
    });

    const isCodequalityTabActive = Boolean(
      document.querySelector('.pipelines-tabs > li > a.codequality-tab.active'),
    );

    if (isCodequalityTabActive) {
      store.dispatch(fetchReportAction);
    } else {
      const tabClickHandler = (e) => {
        if (e.target.className === 'codequality-tab') {
          store.dispatch(fetchReportAction);
          tabsElement.removeEventListener('click', tabClickHandler);
        }
      };

      tabsElement.addEventListener('click', tabClickHandler);
    }

    // eslint-disable-next-line no-new
    new Vue({
      el: codequalityTab,
      components: {
        CodequalityReportApp,
      },
      store,
      render: (createElement) => createElement('codequality-report-app'),
    });
  }
};
