import Vue from 'vue';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';

export const initHandRaiseLeadButton = (el) => {
  const { namespaceId, userName } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(HandRaiseLeadButton, {
        props: {
          namespaceId: Number(namespaceId),
          userName,
        },
      });
    },
  });
};
