import { initProductAnalyticsSettingsInstrumentationInstructions } from 'ee/product_analytics/onboarding';
import initSettingsPanels from '~/settings_panels';
import { initProjectSelects } from '~/vue_shared/components/entity_select/init_project_selects';
import showToast from '~/vue_shared/plugins/global_toast';

initProductAnalyticsSettingsInstrumentationInstructions();
initSettingsPanels();
initProjectSelects();

const toasts = document.querySelectorAll('.js-toast-message');
toasts.forEach((toast) => showToast(toast.dataset.message));
