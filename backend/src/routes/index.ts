import type { Express } from "express";
import { Router } from "express";

import { docsRouter } from "./docs.routes.js";
import { healthRouter } from "./health.routes.js";
import { nfcRouter } from "./nfc.routes.js";

export const registerRoutes = (app: Express): void => {
  // Aggregate feature routers under a single API namespace for clarity.
  const apiRouter = Router();

  // Built-in API documentation endpoint
  apiRouter.use("/docs", docsRouter);
  apiRouter.use("/health", healthRouter);
  apiRouter.use("/nfc", nfcRouter);

  app.use("/api", apiRouter);
};

