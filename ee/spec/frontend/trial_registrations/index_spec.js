import Tracking from '~/tracking';

describe('EnableFormTracking', () => {
  let formTrackingSpy;

  beforeEach(() => {
    setFixtures(`
      <form class="new_user">
        <input type="text" />
        <input class="submit" type="submit">
      </form>
    `);

    formTrackingSpy = jest.spyOn(Tracking, 'enableFormTracking').mockImplementation(() => null);
  });

  it('initialized with the correct configuration', () => {
    Tracking.enableFormTracking({
      forms: { allow: ['new_user'] },
    });

    expect(formTrackingSpy).toHaveBeenCalledWith({
      forms: { allow: ['new_user'] },
    });
  });
});
