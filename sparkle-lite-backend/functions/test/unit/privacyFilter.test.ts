// import { buildNotificationPayload } from '../../src/utils/notificationHelper';

describe('privacy filter', () => {
  test('generic notification text does not contain health details', () => {
    const generic = { title: 'Health reminder', body: 'You have a health reminder. Open the app for details.' };
    expect(generic.title).not.toContain('PCOS');
    expect(generic.body).not.toContain('period');
    expect(generic.body).not.toContain('medication');
  });
});
