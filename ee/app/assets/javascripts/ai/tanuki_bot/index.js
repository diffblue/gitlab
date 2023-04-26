import Vue from 'vue';
import TanukiBotChatApp from './components/app.vue';
import store from './store';

export const initTanukiBotChatDrawer = () => {
  const el = document.getElementById('js-tanuki-bot-chat-app');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(TanukiBotChatApp);
    },
  });
};
