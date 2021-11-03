import Cookies from 'js-cookie';

const handleOnDismiss = ({ currentTarget }) => {
  const {
    dataset: { cookieId },
  } = currentTarget;

  Cookies.set(cookieId, true, { expires: 30 });
};

export default () => {
  const alert = document.querySelector('.js-namespace-user-cap-alert-dismiss');

  if (alert) {
    alert.addEventListener('click', handleOnDismiss);
  }
};
