import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import NamespaceLimitsApp from './components/namespace_limits_app.vue';

Vue.use(GlToast);

initSimpleApp('#js-namespace-limits-app', NamespaceLimitsApp);
