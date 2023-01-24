import Vue from 'vue';
import SignInArkoseApp from './components/sign_in_arkose_app.vue';
import SignUpArkoseApp from './components/sign_up_arkose_app.vue';
import IdentityVerificationArkoseApp from './components/identity_verification_arkose_app.vue';

const FORM_SELECTOR = '.js-arkose-labs-form';
const USERNAME_SELECTOR = `${FORM_SELECTOR} .js-username-field`;
const SUBMIT_SELECTOR = `${FORM_SELECTOR} .js-sign-in-button`;

export const setupArkoseLabs = () => {
  const signInForm = document.querySelector(FORM_SELECTOR);
  const el = signInForm?.querySelector('#js-arkose-labs-challenge');

  if (!el) {
    return null;
  }

  const { apiKey, domain } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(SignInArkoseApp, {
        props: {
          publicKey: apiKey,
          domain,
          formSelector: FORM_SELECTOR,
          usernameSelector: USERNAME_SELECTOR,
          submitSelector: SUBMIT_SELECTOR,
        },
      });
    },
  });
};

export const setupArkoseLabsForSignup = () => {
  const el = document.querySelector('#js-arkose-labs-challenge');

  if (!el) {
    return null;
  }

  const { apiKey, domain } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(SignUpArkoseApp, {
        props: {
          formSelector: FORM_SELECTOR,
          publicKey: apiKey,
          domain,
        },
      });
    },
  });
};

export const setupArkoseLabsForIdentityVerification = () => {
  const el = document.querySelector('#js-arkose-labs-challenge');

  if (!el) {
    return null;
  }

  const { apiKey, domain, sessionVerificationPath } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(IdentityVerificationArkoseApp, {
        props: {
          publicKey: apiKey,
          domain,
          sessionVerificationPath,
        },
      });
    },
  });
};
