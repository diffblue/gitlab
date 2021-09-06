import Vue from 'vue';
import 'ee/registrations/welcome/other_role';
import 'ee/registrations/welcome/jobs_to_be_done';
import { experiment } from '~/experimentation/utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProgressBar from '../components/progress_bar.vue';
import {
  STEPS,
  SUBSCRIPTON_FLOW_STEPS,
  SIGNUP_ONBOARDING_FLOW_STEPS,
  COMBINED_SIGNUP_FLOW_STEPS,
} from '../constants';

export default () => {
  const el = document.getElementById('progress-bar');

  if (!el) return null;

  const isInSubscriptionFlow = parseBoolean(el.dataset.isInSubscriptionFlow);
  const isSignupOnboardingEnabled = parseBoolean(el.dataset.isSignupOnboardingEnabled);

  let steps;

  if (isInSubscriptionFlow) {
    steps = SUBSCRIPTON_FLOW_STEPS;
  } else if (isSignupOnboardingEnabled) {
    experiment('combined_registration', {
      use: () => {
        steps = SIGNUP_ONBOARDING_FLOW_STEPS;
      },
      try: () => {
        steps = COMBINED_SIGNUP_FLOW_STEPS;
      },
    });
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProgressBar, {
        props: { steps, currentStep: STEPS.yourProfile },
      });
    },
  });
};
