export const shouldExtendReactivateTrialButtonMount = async () => {
  const el = document.querySelector('.js-extend-reactivate-trial-button');

  if (el) {
    const { initExtendReactivateTrialButton } = await import(
      /* webpackChunkName: 'init_extend_reactivate_trial_button' */ './init_extend_reactivate_trial_button'
    );
    initExtendReactivateTrialButton(el);
  }
};
