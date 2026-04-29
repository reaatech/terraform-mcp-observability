export interface DashboardPanel {
  title: string;
  type: "stat" | "timeseries" | "bargauge" | "table" | "piechart" | "histogram";
  datasource?: string;
  targets: DashboardTarget[];
  fieldConfig?: Record<string, unknown>;
  gridPos: { h: number; w: number; x: number; y: number };
}

export interface DashboardTarget {
  expr: string;
  legendFormat?: string;
  refId: string;
}

export interface DashboardTemplate {
  name: string;
  query: string;
  type: "query" | "datasource" | "custom";
  datasource?: string;
  current?: { text: string; value: string };
}

export interface DashboardJSON {
  title: string;
  description: string;
  uid: string;
  id: number | null;
  version: number;
  editable: boolean;
  graphTooltip: number;
  schemaVersion: 39;
  tags: string[];
  panels: DashboardPanel[];
  templating?: {
    list: DashboardTemplate[];
  };
  refresh?: string;
  time?: { from: string; to: string };
}

export interface ProvisionsOptions {
  title: string;
  description: string;
  uid: string;
  tags?: string[];
  panels: DashboardPanel[];
  templates?: DashboardTemplate[];
  refresh?: string;
  timeFrom?: string;
  timeTo?: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
}
