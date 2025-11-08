import "dotenv/config";

import cors from "cors";
import express from "express";
import helmet from "helmet";

import { registerDocs } from "./docs/swagger.js";
import { errorHandler } from "./middlewares/errorHandler.js";
import { notFoundHandler } from "./middlewares/notFoundHandler.js";
import { requestContext } from "./middlewares/requestContext.js";
import { registerRoutes } from "./routes/index.js";
import { createLogger } from "./utils/logger.js";

const app = express();
const logger = createLogger("bootstrap");

// Register global middlewares that make the application safer and easier to debug.
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use(requestContext);

// Attach documentation and API routes.
registerDocs(app);
registerRoutes(app);

// Fallback middleware chain to handle unmatched routes and runtime errors.
app.use(notFoundHandler);
app.use(errorHandler);

const port = Number(process.env.PORT ?? 3000);

app.listen(port, () => {
  // Use the shared logger utility to print startup information.
  logger.info(`Server listening on port ${port}`);
});

