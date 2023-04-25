import Vue from 'vue';
import TanukiBotChatApp from './components/app.vue';

export const initTanukiBotChatDrawer = () => {
  const el = document.getElementById('js-tanuki-bot-chat-app');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(TanukiBotChatApp);
    },
  });
};
