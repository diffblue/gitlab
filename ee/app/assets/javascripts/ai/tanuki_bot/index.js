import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import TanukiBotChatApp from './components/app.vue';
import store from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initTanukiBotChatDrawer = () => {
  const el = document.getElementById('js-tanuki-bot-chat-app');

  if (!el) {
    return false;
  }

  const { userId } = el.dataset;

  return new Vue({
    el,
    store,
    apolloProvider,
    render(createElement) {
      return createElement(TanukiBotChatApp, {
        props: {
          userId,
        },
      });
    },
  });
};
