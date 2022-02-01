import { setCookie } from '~/lib/utils/common_utils';

const handleOnDismiss = ({ currentTarget }) => {
  const {
    dataset: { cookieId },
  } = currentTarget;

  setCookie(cookieId, true, { expires: 30 });
};

export default () => {
  const alert = document.querySelector('.js-namespace-user-cap-alert-dismiss');

  if (alert) {
    alert.addEventListener('click', handleOnDismiss);
  }
};
