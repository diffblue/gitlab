import '~/pages/admin/application_settings/general/index';
import { initMaintenanceModeSettings } from 'ee/maintenance_mode_settings';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';

initMaintenanceModeSettings();
initServicePingSettingsClickTracking();
