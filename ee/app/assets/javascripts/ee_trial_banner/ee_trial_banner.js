import { getCookie, setCookie, parseBoolean } from '~/lib/utils/common_utils';

export default class EETrialBanner {
  constructor($trialBanner) {
    this.COOKIE_KEY = 'show_ee_trial_banner';
    this.$trialBanner = $trialBanner;

    this.licenseExpiresOn = new Date(this.$trialBanner.data('licenseExpiry'));
  }

  init() {
    // Wait for navbars to render before querying
    this.setCookies();
    this.$trialBanner.on('click', (e) => this.handleTrialBannerDismiss(e.target));
  }

  /**
   * Trial Expiring/Expired Banner has two stages;
   * 1. Show banner when user enters last 7 days of trial
   * 2. Show banner again when last 7 days are over and license has expired
   *
   * Stage 1:
   *    Banner is showed when `trial_license_message` is sent by backend
   *    for the first time (in `app/views/layouts/header/_default.html.haml`).
   *    Here, we perform following steps;
   *
   *    1. Set cookie `show_ee_trial_banner` with expiry same as license
   *    2. Set cookie value to `true`
   *    3. Show banner using `toggleBanner(true)`
   *
   *    At this stage, if user dismisses banner, we set cookie value to `false`
   *    and everytime page is initialized, we check for cookie existence as
   *    well as its value, and decide show/hide status of banner
   *
   * Stage 2:
   *    At this point, Cookie we had set earlier will be expired and
   *    backend will now send updated message in `trial_license_message`.
   *    Here, we perform following steps;
   *
   *    1. Check if cookie is defined (it'll not be defined as it is expired now)
   *    2. If cookie is gone, we re-set `show_ee_trial_banner` cookie but with
   *       expiry of 20 years
   *    3. Set cookie value to `true`
   *    4. Show banner using `toggleBanner(true)`, which now has updated message
   *
   *    At this stage, if user dismisses banner, we set cookie value to `false`
   *    and our existing logic of show/hide banner based on cookie value continues
   *    to work. And since, cookie is set to expire after 20 years, user won't be
   *    seeing banner again.
   */
  setCookies() {
    const today = new Date();

    // Check if Cookie is defined
    if (!getCookie(this.COOKIE_KEY)) {
      // Cookie was not defined, let's define with default value

      // Check if License is yet to expire
      if (today < this.licenseExpiresOn) {
        // License has not expired yet, we show initial banner of 7 days
        // with cookie set to validity same as license expiry
        setCookie(this.COOKIE_KEY, 'true', { expires: this.licenseExpiresOn });
      } else {
        // License is already expired so we show final Banner with cookie set to 20 years validity.
        setCookie(this.COOKIE_KEY, 'true', { expires: 7300 });
      }

      this.toggleBanner(true);
    } else {
      // Cookie was defined, let's read value and show/hide banner
      this.toggleBanner(parseBoolean(getCookie(this.COOKIE_KEY)));
    }
  }

  toggleBanner(state) {
    this.$trialBanner.toggleClass('hidden', !state);
  }

  handleTrialBannerDismiss(element) {
    // Check if a close button or an element inside it was clicked inside the parent alert component
    if (!element.closest('.js-close')) {
      return;
    }

    // A closed button has been clicked, dismiss the banner and handle setting the cookie
    this.toggleBanner(false);
    if (getCookie(this.COOKIE_KEY)) {
      setCookie(this.COOKIE_KEY, 'false');
    }
  }
}
