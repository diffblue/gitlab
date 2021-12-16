import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import {
  SBOM_BANNER_LOCAL_STORAGE_KEY,
  SBOM_BANNER_CURRENT_ID,
  SBOM_SURVEY_LINK,
  SBOM_SURVEY_DAYS_TO_ASK_LATER,
  SBOM_SURVEY_TITLE,
  SBOM_SURVEY_BUTTON_TEXT,
  SBOM_SURVEY_DESCRIPTION,
  SBOM_SURVEY_TOAST_MESSAGE,
} from 'ee/vue_shared/constants';
import sbomBanner from 'ee/sbom_banner/components/app.vue';
import sharedSurveyBanner from 'ee/vue_shared/survey_banner/survey_banner.vue';

describe('Sbom Banner Component', () => {
  let wrapper;
  const findSharedSurveyBanner = () => wrapper.findComponent(sharedSurveyBanner);

  const createComponent = (sbomSurvey = { sbomSurvey: true }) => {
    wrapper = extendedWrapper(
      mount(sbomBanner, {
        propsData: {
          sbomSurveySvgPath: 'foo.svg',
        },
        provide: { glFeatures: { ...sbomSurvey } },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given a true sbom_survey flag', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the SBOM Banner component with the right props', () => {
      const surveyBanner = findSharedSurveyBanner();
      expect(surveyBanner.exists()).toBe(true);
      expect(surveyBanner.props()).toMatchObject({
        bannerId: SBOM_BANNER_CURRENT_ID,
        storageKey: SBOM_BANNER_LOCAL_STORAGE_KEY,
        daysToAskLater: SBOM_SURVEY_DAYS_TO_ASK_LATER,
        surveyLink: SBOM_SURVEY_LINK,
        svgPath: wrapper.props().sbomSurveySvgPath,
        title: SBOM_SURVEY_TITLE,
        toastMessage: SBOM_SURVEY_TOAST_MESSAGE,
      });
      expect(surveyBanner.props('buttonText')).toContain(SBOM_SURVEY_BUTTON_TEXT);
      expect(surveyBanner.props('description')).toContain(SBOM_SURVEY_DESCRIPTION);
    });
  });

  describe('given a false sbom_survey flag', () => {
    beforeEach(() => {
      createComponent({ sbomSurvey: false });
    });

    it('does not render the SBOM Banner component', () => {
      const surveyBanner = findSharedSurveyBanner();
      expect(surveyBanner.exists()).toBe(false);
    });
  });
});
