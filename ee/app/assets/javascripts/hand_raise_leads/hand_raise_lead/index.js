export const shouldHandRaiseLeadButtonMount = async () => {
  const elements = document.querySelectorAll('.js-hand-raise-lead-button');
  if (elements.length > 0) {
    const { initHandRaiseLeadButton } = await import(
      /* webpackChunkName: 'init_hand_raise_lead_button' */ './init_hand_raise_lead_button'
    );

    elements.forEach(async (el) => {
      initHandRaiseLeadButton(el);
    });
  }
};
