import SurveyBanner from './survey_banner.vue';

export default {
  component: SurveyBanner,
  title: 'ee/vue_shared/survey_banner',
};

const Template = (args, { argTypes }) => ({
  components: { SurveyBanner },
  props: Object.keys(argTypes),
  template: '<survey-banner v-bind="$props" />',
});

export const Default = Template.bind({});

Default.args = {
  surveyLink: 'testlink.test',
  daysToAskLater: 7,
  title: 'Shared Survey Banner Test Title',
  buttonText: 'Shared Survey Banner Button Text',
  description: 'Shared Survey Banner Test Description',
  toastMessage: 'Shared Survey Banner Test ToastMessage',
  storageKey: 'testStorageKey',
  bannerId: 'testbannerID',
  svgPath: 'https://gitlab-org.gitlab.io/gitlab-svgs/dist/illustrations/monitoring/tracing.svg',
};
