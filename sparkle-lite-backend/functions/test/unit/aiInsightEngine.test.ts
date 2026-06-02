import { aiInsightEngine } from '../../src/utils/aiInsightEngine';

const makeLog = (overrides = {}) => ({
  id: 'log1',
  userId: 'user1',
  date: { toDate: () => new Date() },
  periodStatus: 'ongoing',
  flowLevel: 'medium',
  painLevel: 3,
  mood: 'calm',
  symptoms: [],
  notes: '',
  ...overrides,
});

describe('aiInsightEngine', () => {
  test('returns wellness summary when no symptoms logged', () => {
    const logs = [makeLog({ painLevel: 0, symptoms: [], mood: 'calm' })];
    const result = aiInsightEngine(logs, 'user1');
    expect(result.summary).toBeTruthy();
    expect(result.disclaimer).toContain('not a medical diagnosis');
  });

  test('triggers high pain guidance when painLevel >= 8', () => {
    const logs = [makeLog({ painLevel: 9, symptoms: ['cramps'] })];
    const result = aiInsightEngine(logs, 'user1');
    expect(result.careGuidance.toLowerCase()).toContain('doctor');
    expect(result.doctorQuestions.length).toBeGreaterThan(0);
  });

  test('triggers irregular bleeding guidance', () => {
    const logs = [makeLog({ symptoms: ['irregularBleeding'], painLevel: 3 })];
    const result = aiInsightEngine(logs, 'user1');
    expect(result.possiblePattern.toLowerCase()).toContain('irregular');
  });

  test('NEVER contains forbidden diagnostic phrases', () => {
    const forbiddenPhrases = ['you have pcos', 'you are pregnant', 'you have cancer', 'definitely normal', 'you do not need a doctor'];
    const logs = [
      makeLog({ painLevel: 9, symptoms: ['cramps', 'irregularBleeding'] }),
      makeLog({ flowLevel: 'heavy', notes: 'feeling dizzy' }),
    ];
    const result = aiInsightEngine(logs, 'user1');
    const allText = [result.summary, result.possiblePattern, result.careGuidance, ...result.doctorQuestions].join(' ').toLowerCase();
    forbiddenPhrases.forEach(phrase => {
      expect(allText).not.toContain(phrase);
    });
  });

  test('disclaimer is always present and complete', () => {
    const logs = [makeLog()];
    const result = aiInsightEngine(logs, 'user1');
    expect(result.disclaimer).toContain('not a medical diagnosis');
    expect(result.disclaimer).toContain('consult a qualified healthcare provider');
  });

  test('heavy flow + dizziness triggers stronger guidance', () => {
    const logs = [makeLog({ flowLevel: 'heavy', notes: 'very dizzy today', painLevel: 5 })];
    const result = aiInsightEngine(logs, 'user1');
    expect(result.careGuidance.toLowerCase()).toContain('doctor');
  });
});
