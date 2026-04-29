import { describe, it, expect } from "vitest";
import { generateDashboard, validateDashboard, provisionDashboards, createPanel } from "./index";
import type { DashboardJSON, DashboardPanel, ProvisionsOptions } from "./types";

const samplePanel: DashboardPanel = {
  title: "Test Panel",
  type: "stat",
  datasource: "${datasource}",
  targets: [
    {
      expr: "rate(gen_ai_client_operation_duration_count[5m])",
      legendFormat: "{{gen_ai_request_model}}",
      refId: "A",
    },
  ],
  gridPos: { h: 4, w: 6, x: 0, y: 0 },
};

const baseOptions: ProvisionsOptions = {
  title: "Test Dashboard",
  description: "A test dashboard",
  uid: "test-dashboard",
  panels: [samplePanel],
};

describe("generateDashboard", () => {
  it("generates a valid dashboard JSON structure", () => {
    const dashboard = generateDashboard(baseOptions);

    expect(dashboard.title).toBe("Test Dashboard");
    expect(dashboard.description).toBe("A test dashboard");
    expect(dashboard.uid).toBe("test-dashboard");
    expect(dashboard.tags).toContain("mcp-observability");
    expect(dashboard.panels).toHaveLength(1);
    expect(dashboard.refresh).toBe("1h");
    expect(dashboard.time!.from).toBe("now-6h");
    expect(dashboard.time!.to).toBe("now");
  });

  it("includes default template variables", () => {
    const dashboard = generateDashboard(baseOptions);
    expect(dashboard.templating).toBeDefined();

    const templateNames = dashboard.templating!.list.map((t) => t.name);
    expect(templateNames).toContain("datasource");
    expect(templateNames).toContain("cluster");
    expect(templateNames).toContain("environment");
  });

  it("accepts custom refresh and time ranges", () => {
    const dashboard = generateDashboard({
      ...baseOptions,
      refresh: "30s",
      timeFrom: "now-1h",
      timeTo: "now-5m",
    });
    expect(dashboard.refresh).toBe("30s");
    expect(dashboard.time!.from).toBe("now-1h");
    expect(dashboard.time!.to).toBe("now-5m");
  });

  it("accepts custom templates", () => {
    const customTemplates = [
      {
        name: "model",
        query: "label_values(gen_ai_request_model)",
        type: "query" as const,
      },
    ];
    const dashboard = generateDashboard({
      ...baseOptions,
      templates: customTemplates,
    });
    expect(dashboard.templating!.list).toEqual(customTemplates);
  });
});

describe("validateDashboard", () => {
  const validDashboard: DashboardJSON = generateDashboard(baseOptions);

  it("passes a valid dashboard", () => {
    const result = validateDashboard(validDashboard);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  it("rejects missing title", () => {
    const result = validateDashboard({ ...validDashboard, title: "" });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("title"))).toBe(true);
  });

  it("rejects missing uid", () => {
    const result = validateDashboard({ ...validDashboard, uid: "" });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("uid"))).toBe(true);
  });

  it("rejects too few panels when minPanels set", () => {
    const result = validateDashboard(validDashboard, { minPanels: 3 });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("panel(s)"))).toBe(true);
  });

  it("rejects undefined panels", () => {
    const noPanels = { ...validDashboard } as Partial<DashboardJSON>;
    delete noPanels.panels;
    const result = validateDashboard(noPanels as DashboardJSON);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("panel(s)"))).toBe(true);
  });

  it("rejects panel with missing targets", () => {
    const badDashboard = {
      ...validDashboard,
      panels: [{ ...samplePanel, targets: [] }],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("target"))).toBe(true);
  });

  it("rejects panel with empty target expression", () => {
    const badDashboard = {
      ...validDashboard,
      panels: [
        {
          ...samplePanel,
          targets: [{ expr: "", refId: "A" }],
        },
      ],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("expression is required"))).toBe(true);
  });

  it("rejects panel with missing grid position", () => {
    const noGridPos = { ...samplePanel } as Partial<DashboardPanel>;
    delete noGridPos.gridPos;
    const badDashboard = {
      ...validDashboard,
      panels: [noGridPos as DashboardPanel],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("grid position"))).toBe(true);
  });

  it("rejects panel with zero-height grid", () => {
    const badDashboard = {
      ...validDashboard,
      panels: [{ ...samplePanel, gridPos: { h: 0, w: 1, x: 0, y: 0 } }],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("height and width"))).toBe(true);
  });

  it("rejects panel with zero-width grid", () => {
    const badDashboard = {
      ...validDashboard,
      panels: [{ ...samplePanel, gridPos: { h: 1, w: 0, x: 0, y: 0 } }],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("height and width"))).toBe(true);
  });

  it("rejects panel with invalid type", () => {
    const badDashboard = {
      ...validDashboard,
      panels: [{ ...samplePanel, type: "unknown-type" as DashboardPanel["type"] }],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("invalid panel type"))).toBe(true);
  });

  it("rejects panel with empty title", () => {
    const badDashboard = {
      ...validDashboard,
      panels: [{ ...samplePanel, title: "" }],
    };
    const result = validateDashboard(badDashboard);
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.includes("panel title"))).toBe(true);
  });
});

describe("provisionDashboards", () => {
  it("returns dashboards with no errors when valid", () => {
    const dashboards = [
      generateDashboard(baseOptions),
      generateDashboard({
        ...baseOptions,
        title: "Second",
        uid: "second-dash",
      }),
    ];
    const result = provisionDashboards(dashboards);
    expect(result.errors).toHaveLength(0);
  });

  it("detects duplicate uids", () => {
    const dashboards = [generateDashboard(baseOptions), generateDashboard(baseOptions)];
    const result = provisionDashboards(dashboards);
    expect(result.errors.some((e) => e.includes("duplicate"))).toBe(true);
  });
});

describe("createPanel", () => {
  it("creates a panel with correct fields", () => {
    const panel = createPanel("My Panel", "timeseries", [{ expr: "up", refId: "A" }], {
      h: 8,
      w: 12,
      x: 0,
      y: 0,
    });
    expect(panel.title).toBe("My Panel");
    expect(panel.type).toBe("timeseries");
    expect(panel.datasource).toBe("${datasource}");
    expect(panel.targets).toHaveLength(1);
  });

  it("omits fieldConfig when passed undefined", () => {
    const panel = createPanel(
      "No Config",
      "stat",
      [{ expr: "1", refId: "A" }],
      { h: 4, w: 4, x: 0, y: 0 },
      undefined,
    );
    expect("fieldConfig" in panel).toBe(false);
  });
});
