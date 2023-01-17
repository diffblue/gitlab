import '~/pages/admin/application_settings/general/index';
import initAddLicenseApp from 'ee/admin/application_settings/general/add_license';
import { initScimTokenApp } from 'ee/saml_sso';
import { initAdminDeletionProtectionSettings } from 'ee/admin/application_settings/deletion_protection';
import { initMaintenanceModeSettings } from 'ee/maintenance_mode_settings';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';
import initDatePicker from '~/behaviors/date_picker';

initAdminDeletionProtectionSettings();
initMaintenanceModeSettings();
initServicePingSettingsClickTracking();
initAddLicenseApp();
initScimTokenApp();
// Used for dashboard_limit_new_namespace_creation_enforcement_date field
initDatePicker();
