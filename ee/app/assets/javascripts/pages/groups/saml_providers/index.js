import Vue from 'vue';

import { initScimTokenApp } from 'ee/saml_sso';

import MembersApp from './saml_members/index.vue';
import createStore from './saml_members/store';
import initSAML from './shared/init_saml';

function initMembers(el) {
  const { groupId } = el.dataset;
  const store = createStore({
    groupId: Number(groupId),
  });
  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    render(createElement) {
      return createElement(MembersApp);
    },
  });
}

const el = document.querySelector('.js-saml-members');
initMembers(el);
initSAML();
initScimTokenApp();
