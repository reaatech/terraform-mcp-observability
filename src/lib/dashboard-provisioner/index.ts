import type { DashboardJSON, DashboardPanel, ProvisionsOptions, ValidationResult } from "./types";

export function generateDashboard(options: ProvisionsOptions): DashboardJSON {
  return {
    title: options.title,
    description: options.description,
    uid: options.uid,
    id: null,
    version: 0,
    editable: true,
    graphTooltip: 0,
    schemaVersion: 39,
    tags: options.tags ?? ["mcp-observability"],
    panels: options.panels,
    templating: options.templates
      ? { list: options.templates }
      : {
          list: [
            {
              name: "datasource",
              query: "prometheus",
              type: "datasource",
              current: { text: "AMP", value: "prometheus" },
            },
            {
              name: "cluster",
              query: "label_values(cluster)",
              type: "query",
              datasource: "${datasource}",
            },
            {
              name: "environment",
              query: "label_values(environment)",
              type: "query",
              datasource: "${datasource}",
            },
          ],
        },
    refresh: options.refresh ?? "1h",
    time: {
      from: options.timeFrom ?? "now-6h",
      to: options.timeTo ?? "now",
    },
  };
}

export function validateDashboard(
  dashboard: DashboardJSON,
  options?: { minPanels?: number },
): ValidationResult {
  const errors: string[] = [];

  if (!dashboard.title || dashboard.title.trim() === "") {
    errors.push("dashboard title is required");
  }

  if (!dashboard.uid || dashboard.uid.trim() === "") {
    errors.push("dashboard uid is required");
  }

  const minPanels = options?.minPanels ?? 1;
  if (!dashboard.panels || dashboard.panels.length < minPanels) {
    errors.push(
      `dashboard must have at least ${minPanels} panel(s), found ${dashboard.panels?.length ?? 0}`,
    );
  }

  for (const panel of dashboard.panels ?? []) {
    const panelErrors = validatePanel(panel);
    errors.push(...panelErrors.map((e) => `panel "${panel.title}": ${e}`));
  }

  return { valid: errors.length === 0, errors };
}

function validatePanel(panel: DashboardPanel): string[] {
  const errors: string[] = [];

  if (!panel.title || panel.title.trim() === "") {
    errors.push("panel title is required");
  }

  const validTypes = ["stat", "timeseries", "bargauge", "table", "piechart", "histogram"];
  if (!validTypes.includes(panel.type)) {
    errors.push(`invalid panel type '${panel.type}', must be one of: ${validTypes.join(", ")}`);
  }

  if (!panel.targets || panel.targets.length === 0) {
    errors.push("panel must have at least one target");
  } else {
    for (const target of panel.targets) {
      if (!target.expr || target.expr.trim() === "") {
        errors.push(`target ${target.refId}: expression is required`);
      }
    }
  }

  if (!panel.gridPos) {
    errors.push("grid position is required");
  } else {
    if (panel.gridPos.h < 1 || panel.gridPos.w < 1) {
      errors.push("grid height and width must be >= 1");
    }
  }

  return errors;
}

export function provisionDashboards(dashboards: DashboardJSON[]): {
  dashboards: DashboardJSON[];
  errors: string[];
} {
  const errors: string[] = [];
  const uids = new Set<string>();

  for (const dash of dashboards) {
    if (uids.has(dash.uid)) {
      errors.push(`duplicate dashboard uid: ${dash.uid}`);
    }
    uids.add(dash.uid);

    const result = validateDashboard(dash);
    errors.push(...result.errors);
  }

  return { dashboards, errors };
}

export function createPanel(
  title: string,
  type: DashboardPanel["type"],
  targets: DashboardPanel["targets"],
  gridPos: DashboardPanel["gridPos"],
  fieldConfig?: Record<string, unknown>,
): DashboardPanel {
  return {
    title,
    type,
    datasource: "${datasource}",
    targets,
    gridPos,
    ...(fieldConfig !== undefined ? { fieldConfig } : {}),
  };
}
