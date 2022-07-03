import Vue from 'vue';
import Form from './form.vue';

export default () => {
  const root = '#js-google-cloud-service-accounts';
  const element = document.querySelector(root);
  const { screen, ...attrs } = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(Form, { props: { screen }, attrs }),
  });
};
