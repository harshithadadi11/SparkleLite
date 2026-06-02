import { AIInsight } from './models';

export interface GenerateInsightRequest {
  logIds: string[];
}

export interface GenerateInsightResponse {
  insightId: string;
  insight: AIInsight;
}
