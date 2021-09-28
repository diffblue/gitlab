import { getExperimentContexts } from '~/experimentation/utils';
import Tracking from '~/tracking';

const select = document.querySelector('.js-jobs-to-be-done-dropdown');
if (select) {
  Tracking.enableFormTracking(
    { fields: { allow: ['jobs_to_be_done_other'] } },
    getExperimentContexts('jobs_to_be_done'),
  );

  select.addEventListener('change', () => {
    const otherSelected = select.value === 'other';
    document
      .querySelector('.js-jobs-to-be-done-other-group')
      .classList.toggle('hidden', !otherSelected);
  });
}
