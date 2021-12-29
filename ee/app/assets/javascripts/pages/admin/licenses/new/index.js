import Vue from 'vue';
import LicenseNewApp from 'ee/admin/licenses/new/components/license_new_app.vue';

const licenseFile = document.querySelector('.license-file');
const licenseKey = document.querySelector('.license-key');
const acceptEULACheckBox = document.querySelector('#accept_eula');
const uploadLicenseBtn = document.querySelector('#js-upload-license');
const licenseType = document.querySelectorAll('input[name="license_type"]');

const showLicenseType = () => {
  const checkedFile = document.querySelector('input[name="license_type"]:checked').value === 'file';

  licenseFile.classList.toggle('hidden', !checkedFile);
  licenseKey.classList.toggle('hidden', checkedFile);
};

const toggleUploadLicenseButton = () => {
  uploadLicenseBtn.toggleAttribute('disabled', !acceptEULACheckBox.checked);
};

const initLicenseUploadDropzone = () => {
  const el = document.getElementById('js-license-new-app');

  return new Vue({
    el,
    components: {
      LicenseNewApp,
    },
    render(createElement) {
      return createElement(LicenseNewApp);
    },
  });
};

licenseType.forEach((el) => el.addEventListener('change', showLicenseType));
acceptEULACheckBox.addEventListener('change', toggleUploadLicenseButton);
showLicenseType();
initLicenseUploadDropzone();
