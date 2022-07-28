import { GlBanner } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import FeedbackBanner from 'ee/project_quality_summary/components/feedback_banner.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { i18n, FEEDBACK_ISSUE_URL } from 'ee/project_quality_summary/constants';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Project quality summary feedback banner', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const findBanner = () => wrapper.findComponent(GlBanner);

  const createComponent = ({ shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = mountExtended(FeedbackBanner, {
      provide: {
        projectQualitySummaryFeedbackImagePath: 'banner/image/path',
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  it('is displayed with the correct props', () => {
    createComponent();

    expect(findBanner().props()).toMatchObject({
      title: i18n.banner.title,
      buttonLink: FEEDBACK_ISSUE_URL,
      buttonText: i18n.banner.button,
      svgPath: 'banner/image/path',
    });
  });

  it('dismisses the callout when closed', () => {
    createComponent();

    findBanner().vm.$emit('close');

    expect(userCalloutDismissSpy).toHaveBeenCalled();
  });

  it('is not displayed once it has been dismissed', () => {
    createComponent({ shouldShowCallout: false });

    expect(findBanner().exists()).toBe(false);
  });
});
