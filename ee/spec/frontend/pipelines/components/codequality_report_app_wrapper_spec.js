import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import CodequalityReportAppGraphql from 'ee/codequality_report/codequality_report_graphql.vue';
import CodequalityReportAppWrapper from 'ee/pipelines/components/codequality_report_app_wrapper.vue';

describe('Codequality report app wrapper', () => {
  let wrapper;

  const findCodeQualityApp = () => wrapper.findComponent(CodequalityReportApp);
  const findCodeQualityAppGraphql = () => wrapper.findComponent(CodequalityReportAppGraphql);

  const defaultProvide = {
    codequalityProjectPath: '',
    codequalityBlobPath: '',
    codequalityReportDownloadPath: '',
    pipelineIid: '0',
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CodequalityReportAppWrapper, {
        provide: {
          ...defaultProvide,
          ...provide,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    ffEnabled
    ${true}
    ${false}
  `('Show the correct code quality app When graphQL ff is $ffEnabled', ({ ffEnabled }) => {
    createComponent({
      provide: {
        canGenerateCodequalityReports: true,
        glFeatures: {
          graphqlCodeQualityFullReport: ffEnabled,
        },
      },
    });

    expect(findCodeQualityAppGraphql().exists()).toBe(ffEnabled);
    expect(findCodeQualityApp().exists()).toBe(!ffEnabled);
  });
});
