import Vue from 'vue';
import mountVisibilityLevelDropdown from '~/groups/visibility_level';
import 'ee/pages/trials/country_select';
import ProgressBar from '../../components/progress_bar.vue';
import RegistrationTrialToggle from '../../components/registration_trial_toggle.vue';
import { STEPS, SIGNUP_ONBOARDING_FLOW_STEPS } from '../../constants';

function mountProgressBar() {
  const el = document.getElementById('progress-bar');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProgressBar, {
        props: { steps: SIGNUP_ONBOARDING_FLOW_STEPS, currentStep: STEPS.yourGroup },
      });
    },
  });
}

function toggleTrialForm(trial) {
  const form = document.querySelector('.js-trial-form');
  const fields = document.querySelectorAll('.js-trial-field');

  if (!form) {
    return null;
  }

  form.classList.toggle('hidden', !trial);
  fields.forEach((f) => {
    f.disabled = !trial; // eslint-disable-line no-param-reassign
  });

  return trial;
}

function mountTrialToggle() {
  const el = document.querySelector('.js-trial-toggle');

  if (!el) {
    return null;
  }

  const { active } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(RegistrationTrialToggle, {
        props: { active },
        on: {
          changed: (event) => toggleTrialForm(event.trial),
        },
      });
    },
  });
}

export default () => {
  mountProgressBar();
  mountVisibilityLevelDropdown();
  mountTrialToggle();
};
