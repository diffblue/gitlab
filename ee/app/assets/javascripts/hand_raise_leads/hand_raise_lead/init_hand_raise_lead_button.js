import Vue from 'vue';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';

export const initHandRaiseLeadButton = (el) => {
  const {
    namespaceId,
    userName,
    firstName,
    lastName,
    companyName,
    glmContent,
    trackAction,
    trackLabel,
    trackProperty,
    trackValue,
    trackExperiment,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      small: Boolean(el.hasAttribute('small')),
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
      },
      ctaTracking: {
        action: trackAction,
        label: trackLabel,
        property: trackProperty,
        value: trackValue,
        experiment: trackExperiment,
      },
    },
    render(createElement) {
      return createElement(HandRaiseLeadButton);
    },
  });
};
