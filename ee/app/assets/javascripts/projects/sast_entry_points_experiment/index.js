import Vue from 'vue';
import Banner from './components/banner.vue';
import PopoverDark from './components/popover_dark.vue';
import PopoverLight from './components/popover_light.vue';

export const initSastEntryPointsExperiment = () => {
  const el = document.querySelector('.js-sast-entry-points-experiment');

  if (!el) return false;

  const { variant, sastDocumentationPath } = el.dataset;

  const component = {
    banner: Banner,
    popover_dark: PopoverDark,
    popover_light: PopoverLight,
  }[variant];

  if (!component) return false;

  return new Vue({
    el,
    render(h) {
      return h(component, {
        props: {
          sastDocumentationPath,
        },
      });
    },
  });
};
