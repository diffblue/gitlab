import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  SURVEY_BANNER_LOCAL_STORAGE_KEY,
  SURVEY_BANNER_CURRENT_ID,
  SURVEY_LINK,
  SURVEY_DAYS_TO_ASK_LATER,
  SURVEY_TITLE,
  SURVEY_TOAST_MESSAGE,
  SURVEY_BUTTON_TEXT,
  SURVEY_DESCRIPTION,
} from 'ee/security_dashboard/constants';

import SurveyRequestBanner from 'ee/security_dashboard/components/shared/survey_request_banner.vue';
import sharedSurveyBanner from 'ee/vue_shared/survey_banner/survey_banner.vue';

describe('SurveyRequestBanner Component', () => {
  let wrapper;
  const findSharedSurveyBanner = () => wrapper.findComponent(sharedSurveyBanner);

  const SURVEY_REQUEST_SVG_PATH = 'foo.svg';

  const createComponent = (
    vulnerabilityManagementSurvey = { vulnerabilityManagementSurvey: true },
  ) => {
    wrapper = extendedWrapper(
      mount(SurveyRequestBanner, {
        provide: {
          glFeatures: { ...vulnerabilityManagementSurvey },
          surveyRequestSvgPath: SURVEY_REQUEST_SVG_PATH,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent();
  });

  describe('given a true vulnerability_management_survey flag', () => {
    it('renders the SurveyRequestBanner component with the right props', () => {
      const surveyBanner = findSharedSurveyBanner();
      expect(surveyBanner.exists()).toBe(true);

      expect(surveyBanner.props()).toMatchObject({
        bannerId: SURVEY_BANNER_CURRENT_ID,
        storageKey: SURVEY_BANNER_LOCAL_STORAGE_KEY,
        daysToAskLater: SURVEY_DAYS_TO_ASK_LATER,
        surveyLink: SURVEY_LINK,
        svgPath: SURVEY_REQUEST_SVG_PATH,
        title: SURVEY_TITLE,
        toastMessage: SURVEY_TOAST_MESSAGE,
      });
      expect(surveyBanner.props('buttonText')).toContain(SURVEY_BUTTON_TEXT);
      expect(surveyBanner.props('description')).toContain(SURVEY_DESCRIPTION);
    });
  });

  describe('given a false vulnerability_management_survey flag', () => {
    beforeEach(() => {
      createComponent({ vulnerabilityManagementSurvey: false });
    });

    it('does not renders the SurveyRequestBanner', () => {
      const surveyBanner = findSharedSurveyBanner();
      expect(surveyBanner.exists()).toBe(false);
    });
  });
});
