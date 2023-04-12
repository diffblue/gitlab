import Vue from 'vue';
import VueRouter from 'vue-router';
import WorkspacesList from '../pages/list.vue';

Vue.use(VueRouter);

export default function createRouter({ base }) {
  const routes = [
    {
      path: '/',
      name: 'index',
      component: WorkspacesList,
    },
    {
      path: '*',
      redirect: '/',
    },
  ];

  return new VueRouter({
    base,
    mode: 'history',
    routes,
  });
}
