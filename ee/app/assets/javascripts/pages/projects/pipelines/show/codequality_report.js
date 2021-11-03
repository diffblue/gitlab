import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import CodequalityReportAppGraphQL from 'ee/codequality_report/codequality_report_graphql.vue';
import createStore from 'ee/codequality_report/store';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const tabsElement = document.querySelector('.pipelines-tabs');
  const codequalityTab = document.getElementById('js-pipeline-codequality-report');
  const isGraphqlFeatureFlagEnabled = gon.features?.graphqlCodeQualityFullReport;

  if (tabsElement && codequalityTab) {
    const fetchReportAction = 'fetchReport';
    const {
      codequalityReportDownloadPath,
      blobPath,
      projectPath,
      pipelineIid,
    } = codequalityTab.dataset;
    const isCodequalityTabActive = Boolean(
      document.querySelector('.pipelines-tabs > li > a.codequality-tab.active'),
    );

    if (isGraphqlFeatureFlagEnabled) {
      const vueOptions = {
        el: codequalityTab,
        apolloProvider,
        components: {
          CodequalityReportApp: CodequalityReportAppGraphQL,
        },
        provide: {
          projectPath,
          pipelineIid,
          blobPath,
        },
        render: (createElement) => createElement('codequality-report-app'),
      };

      if (isCodequalityTabActive) {
        // eslint-disable-next-line no-new
        new Vue(vueOptions);
      } else {
        const tabClickHandler = (e) => {
          if (e.target.className === 'codequality-tab') {
            // eslint-disable-next-line no-new
            new Vue(vueOptions);
            tabsElement.removeEventListener('click', tabClickHandler);
          }
        };
        tabsElement.addEventListener('click', tabClickHandler);
      }
    } else {
      const store = createStore({
        endpoint: codequalityReportDownloadPath,
        blobPath,
        projectPath,
        pipelineIid,
      });

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
  }
};
