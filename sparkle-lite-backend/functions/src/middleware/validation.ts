import * as functions from 'firebase-functions';
import { z } from 'zod';

export function validateRequest<T>(schema: z.ZodSchema<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid request: ${result.error.issues.map(i => i.message).join(', ')}`
    );
  }
  return result.data;
}

// Zod schemas for all callable function inputs
export const generateInsightSchema = z.object({
  logIds: z.array(z.string().min(1)).min(1).max(30),
});

export const generateSummarySchema = z.object({
  questionsToAsk: z.array(z.string()).optional(),
  userNotes: z.string().max(2000).optional(),
});

export const deleteAccountSchema = z.object({
  confirmationText: z.literal('DELETE'),
});
