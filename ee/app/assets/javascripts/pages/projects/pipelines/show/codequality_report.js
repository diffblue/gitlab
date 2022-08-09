import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import CodequalityReportAppGraphQL from 'ee/codequality_report/codequality_report_graphql.vue';

Vue.use(Translate);
Vue.use(VueApollo);
Vue.use(Vuex);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const tabsElement = document.querySelector('.pipelines-tabs');
  const codequalityTab = document.getElementById('js-pipeline-codequality-report');
  const isGraphqlFeatureFlagEnabled = gon.features?.graphqlCodeQualityFullReport;

  if (tabsElement && codequalityTab) {
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
      const initialState = {
        endpoint: codequalityReportDownloadPath,
        blobPath,
        projectPath,
        pipelineIid,
      };

      // eslint-disable-next-line no-new
      new Vue({
        el: codequalityTab,
        components: {
          CodequalityReportApp,
        },
        store: new Vuex.Store(),
        render: (createElement) =>
          createElement('codequality-report-app', {
            props: initialState,
          }),
      });
    }
  }
};
