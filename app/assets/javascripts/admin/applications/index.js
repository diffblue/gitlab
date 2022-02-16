import Vue from 'vue';
import DeleteApplication from './components/delete_application.vue';

export default () => {
  const elements = document.querySelectorAll('.js-application-delete-button');

  if (!elements) {
    return false;
  }

  return elements.forEach((el) => {
    const { path, name } = el.dataset;

    return new Vue({
      el,
      provide: {
        path,
        name,
      },
      render(h) {
        return h(DeleteApplication);
      },
    });
  });
};
