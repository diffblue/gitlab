import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { convertObjectPropsToLowerCase } from '~/lib/utils/common_utils';
import ErrorAlert from './error_alert.vue';

export default {
  component: ErrorAlert,
  title: 'ee/vue_shared/components/error_alert',
};

const Template = (args, { argTypes }) => ({
  components: { ErrorAlert },
  props: Object.keys(argTypes),
  template: '<error-alert v-bind="$props" />',
});

const link = `${PROMO_URL}/help`;
const unfriendlyError = 'An unfriendly error';
const unfriendlyErrorThatNeedsLinks = 'An unfriendly error that needs links';
const errorDictionary = convertObjectPropsToLowerCase({
  [unfriendlyError]: {
    message: `I'm a friendly error.`,
    links: {},
  },
  [unfriendlyErrorThatNeedsLinks]: {
    message: `I'm a friendly error with %{linkStart}links%{linkEnd}.`,
    links: { link },
  },
});
const defaultError = {
  message: `Something went wrong, please try again later.`,
  links: {},
};

export const Default = Template.bind({});
Default.args = {
  error: 'An unfriendly error.',
  errorDictionary,
};

export const WithLinksInFriendlyError = Template.bind({});
WithLinksInFriendlyError.args = {
  ...Default.args,
  error: 'An unfriendly error that needs links',
};

export const WithEmptyMessageInError = Template.bind({});
WithEmptyMessageInError.args = {
  ...Default.args,
  error: new Error(),
};

export const WithDefaultErrorButEmptyMessageInError = Template.bind({});
WithDefaultErrorButEmptyMessageInError.args = {
  ...Default.args,
  error: new Error(),
  defaultError,
};

export const WithNoMatchingFriendlyError = Template.bind({});
WithNoMatchingFriendlyError.args = {
  ...Default.args,
  error: 'An unfriendly error with no matching friendly error',
};
