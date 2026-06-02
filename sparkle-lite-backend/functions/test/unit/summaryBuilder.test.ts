import { summaryBuilder } from '../../src/utils/summaryBuilder';

describe('summaryBuilder', () => {
  test('generates summary with no data gracefully', () => {
    const result = summaryBuilder({ profile: null, recentLogs: [], recentRecords: [], questionsToAsk: [] });
    expect(result).toContain('DOCTOR VISIT PREPARATION SUMMARY');
    expect(result).toContain('This summary was prepared by the user');
  });

  test('includes all profile fields when present', () => {
    const profile = { nameOrNickname: 'Priya', ageRange: '25-34', lifeStage: 'periodTracking', medications: 'Folic acid' };
    const result = summaryBuilder({ profile, recentLogs: [], recentRecords: [], questionsToAsk: [] });
    expect(result).toContain('Priya');
    expect(result).toContain('25-34');
    expect(result).toContain('Folic acid');
  });

  test('includes symptom log details', () => {
    const fakeTimestamp = { toDate: () => new Date('2026-05-15') };
    const log = { id: 'l1', periodStatus: 'ongoing', painLevel: 7, mood: 'tired', symptoms: ['cramps'], notes: 'bad day', date: fakeTimestamp };
    const result = summaryBuilder({ profile: null, recentLogs: [log], recentRecords: [], questionsToAsk: [] });
    expect(result).toContain('7/10');
    expect(result).toContain('cramps');
  });

  test('includes doctor questions', () => {
    const result = summaryBuilder({ profile: null, recentLogs: [], recentRecords: [], questionsToAsk: ['Should I get an ultrasound?'] });
    expect(result).toContain('Should I get an ultrasound?');
  });

  test('always ends with the disclaimer', () => {
    const result = summaryBuilder({ profile: null, recentLogs: [], recentRecords: [], questionsToAsk: [] });
    expect(result).toContain('does not constitute medical advice');
  });
});
