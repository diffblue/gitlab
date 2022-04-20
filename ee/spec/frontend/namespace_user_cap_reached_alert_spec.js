import Cookies from '~/lib/utils/cookies';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initNamespaceUserCapReachedAlert from 'ee/namespace_user_cap_reached_alert';

describe('dismissing the alert', () => {
  const clickDismissButton = () => {
    const button = document.querySelector('.js-namespace-user-cap-alert-dismiss');
    button.click();
  };

  beforeEach(() => {
    setHTMLFixture(`
    <div class="js-namespace-user-cap-alert">
      <button class="js-namespace-user-cap-alert-dismiss" data-cookie-id="hide_user_cap_alert_1" data-level="info"></button>
    </div>
    `);

    initNamespaceUserCapReachedAlert();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('sets the banner to be hidden for thirty days', () => {
    jest.spyOn(Cookies, 'set');

    clickDismissButton();

    expect(Cookies.set).toHaveBeenCalledWith('hide_user_cap_alert_1', true, {
      expires: 30,
      secure: false,
    });
  });
});
