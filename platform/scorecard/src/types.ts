export type ScorecardCheck = {
  id: string;
  title: string;
  passed: boolean;
  message: string;
  evidence: string[];
};

export type ScorecardCategory = {
  id: string;
  title: string;
  passed: boolean;
  checks: ScorecardCheck[];
};

export type ScorecardResult = {
  schemaVersion: 'v1';
  generatedAt: string;
  service: {
    name: string;
    path: string;
  };
  summary: {
    total: number;
    passed: number;
    failed: number;
  };
  categories: ScorecardCategory[];
};

export type EvidenceOptions = {
  ciStatus?: 'pass' | 'fail';
  securityStatus?: 'pass' | 'fail';
  iacStatus?: 'pass' | 'fail';
};
