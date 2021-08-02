import Vue from 'vue';
import ExtendReactivateTrialButton from 'ee/trials/extend_reactivate_trial/components/extend_reactivate_trial_button.vue';

export const initExtendReactivateTrialButton = (el) => {
  const { namespaceId, action, planName } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(ExtendReactivateTrialButton, {
        props: {
          namespaceId: Number(namespaceId),
          planName,
          action,
        },
      });
    },
  });
};
