import CiResourcesPage from '../components/pages/ci_resources_page.vue';
import CiResourceDetailsPage from '../components/pages/ci_resource_details_page.vue';
import { CI_RESOURCES_PAGE_NAME, CI_RESOURCE_DETAILS_PAGE_NAME } from './constants';

export const routes = [
  { name: CI_RESOURCES_PAGE_NAME, path: '', component: CiResourcesPage },
  { name: CI_RESOURCE_DETAILS_PAGE_NAME, path: '/:id', component: CiResourceDetailsPage },
];
