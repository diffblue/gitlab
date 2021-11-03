import Vue from 'vue';
import mountVisibilityLevelDropdown from '~/groups/visibility_level';
import 'ee/pages/trials/country_select';
import RegistrationTrialToggle from '../../components/registration_trial_toggle.vue';

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
  mountVisibilityLevelDropdown();
  mountTrialToggle();
};
