import Vue from 'vue';
import Panel from './panel.vue';

export default () => {
  const root = '#js-google-cloud-databases';
  const element = document.querySelector(root);
  const { screen, ...attrs } = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(Panel, { props: { screen }, attrs }),
  });
};
