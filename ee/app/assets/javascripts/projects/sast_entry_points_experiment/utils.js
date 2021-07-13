import ExperimentTracking from '~/experimentation/experiment_tracking';
import { setCookie, getCookie, parseBoolean } from '~/lib/utils/common_utils';
import { COOKIE_NAME, EXPERIMENT_NAME } from './constants';

const tracking = new ExperimentTracking(EXPERIMENT_NAME);

export const isDismissed = () => {
  return parseBoolean(getCookie(COOKIE_NAME));
};

export const dismiss = () => {
  setCookie(COOKIE_NAME, 'true');
  tracking.event('dismissed');
};

export const trackShow = () => {
  tracking.event('show');
};

export const trackCtaClicked = () => {
  tracking.event('cta_clicked');
};
