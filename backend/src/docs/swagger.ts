import type { Express } from "express";
import swaggerJsdoc, { type OAS3Definition, type OAS3Options } from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";

const swaggerDefinition: OAS3Definition = {
  openapi: "3.1.0",
  info: {
    title: "Tung Tung Tung Sahur API",
    version: "0.1.0",
    description: "API documentation powered by Swagger UI."
  },
  servers: [
    {
      url: "/api",
      description: "Primary API entrypoint"
    }
  ]
};

const swaggerOptions: OAS3Options = {
  definition: swaggerDefinition,
  // Limit source documents to YAML files to avoid TypeScript resolver issues.
  apis: ["./src/docs/**/*.yaml"]
};

const swaggerSpec = (() => {
  try {
    // Precompute the OpenAPI specification so it can be reused across requests.
    return swaggerJsdoc(swaggerOptions);
  } catch (error) {
    console.error("Failed to initialize Swagger specification", error);
    throw error;
  }
})();

export const registerDocs = (app: Express): void => {
  // Mount Swagger UI under /docs to provide interactive API exploration.
  app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));
};

