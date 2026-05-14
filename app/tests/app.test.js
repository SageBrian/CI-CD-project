const request = require("supertest");
const app = require("../src/index");

describe("GET /", () => {
  it("should return 200 and a message", async () => {
    const res = await request(app).get("/");
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("message");
  });
});

describe("GET /health", () => {
  it("should return 200 and healthy status", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe("healthy");
  });
});
