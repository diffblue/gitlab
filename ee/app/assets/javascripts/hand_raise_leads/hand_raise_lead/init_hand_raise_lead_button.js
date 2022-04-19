import Vue from 'vue';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import { PQL_BUTTON_TEXT } from './constants';

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
    buttonAttributes,
    buttonText,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      buttonAttributes: buttonAttributes && JSON.parse(buttonAttributes),
      buttonText: buttonText || PQL_BUTTON_TEXT,
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
