import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import VerificationReminder from './components/verification_reminder.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('.js-verification-reminder');

  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(VerificationReminder);
    },
  });
};
