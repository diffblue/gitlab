import Vue from 'vue';
import store from '~/boards/stores';
import ToggleLabels from './components/toggle_labels.vue';

export default () =>
  new Vue({
    el: document.getElementById('js-board-labels-toggle'),
    name: 'ToggleLabelsRoot',
    components: {
      ToggleLabels,
    },
    store,
    render: (createElement) => createElement('toggle-labels'),
  });
