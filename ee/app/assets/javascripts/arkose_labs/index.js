import Vue from 'vue';
import SignInArkoseApp from './components/sign_in_arkose_app.vue';

const FORM_SELECTOR = '.js-sign-in-form';
const USERNAME_SELECTOR = `${FORM_SELECTOR} .js-username-field`;
const SUBMIT_SELECTOR = `${FORM_SELECTOR} .js-sign-in-button`;

export const setupArkoseLabs = () => {
  const signInForm = document.querySelector(FORM_SELECTOR);
  const el = signInForm?.querySelector('.js-arkose-labs-challenge');

  if (!el) {
    return null;
  }

  const publicKey = el.dataset.apiKey;

  return new Vue({
    el,
    render(h) {
      return h(SignInArkoseApp, {
        props: {
          publicKey,
          formSelector: FORM_SELECTOR,
          usernameSelector: USERNAME_SELECTOR,
          submitSelector: SUBMIT_SELECTOR,
        },
      })
    }
  });
};
