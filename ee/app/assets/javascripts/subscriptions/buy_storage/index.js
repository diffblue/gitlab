import Vue from 'vue';
import App from './components/app.vue';

export default (el) => {
  return new Vue({
    el,
    components: {
      App,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
