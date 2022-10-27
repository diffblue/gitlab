import Vue from 'vue';
import NamespaceSelector from './components/namespace_selector.vue';

const SELECTOR = '.js-namespace-selector';

export const initNamespaceSelector = () => {
  const el = document.querySelector(SELECTOR);

  if (!el) {
    return false;
  }

  const items = JSON.parse(el.dataset.items);
  const { initialValue } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(NamespaceSelector, {
        props: {
          initialValue,
          items,
        },
      }),
  });
};
