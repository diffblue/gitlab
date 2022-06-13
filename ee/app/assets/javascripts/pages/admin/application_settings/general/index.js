import '~/pages/admin/application_settings/general/index';
import initAddLicenseApp from 'ee/admin/application_settings/general/add_license';
import { initAdminDeletionProtectionSettings } from 'ee/admin/application_settings/deletion_protection';
import { initMaintenanceModeSettings } from 'ee/maintenance_mode_settings';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';

initAdminDeletionProtectionSettings();
initMaintenanceModeSettings();
initServicePingSettingsClickTracking();
initAddLicenseApp();
