import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GeoProjectCardErrors from './components/geo_project_card_errors.vue';

Vue.use(Translate);

export const initGeoProjectCardErrors = () => {
  const cardsErrorsContainers = Array.from(document.querySelectorAll('.js-project-card-errors'));

  cardsErrorsContainers.forEach((element) => {
    const { synchronizationFailure, verificationFailure, retryCount } = JSON.parse(
      element.dataset.config,
    );

    const app = new Vue({
      render(h) {
        return h(GeoProjectCardErrors, {
          props: {
            synchronizationFailure,
            verificationFailure,
            retryCount,
          },
        });
      },
    });

    app.$mount(element);
  });
};
