import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';

Vue.use(Translate);
Vue.use(VueApollo);
Vue.use(Vuex);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const tabsElement = document.querySelector('.pipelines-tabs');
  const codequalityTab = document.getElementById('js-pipeline-codequality-report');

  if (tabsElement && codequalityTab) {
    const { blobPath, projectPath, pipelineIid } = codequalityTab.dataset;
    const isCodequalityTabActive = Boolean(
      document.querySelector('.pipelines-tabs > li > a.codequality-tab.active'),
    );

    const vueOptions = {
      el: codequalityTab,
      apolloProvider,
      components: {
        CodequalityReportApp,
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
  }
};
