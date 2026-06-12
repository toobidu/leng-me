import swaggerJsdoc from 'swagger-jsdoc';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'LengMe API Documentation',
      version: '1.0.0',
      description: 'API documentation for the LengMe application, built with Express.js and documented with Swagger.',
    },
    // Thêm định nghĩa cho security scheme (JWT)
    // Tương đương với @SecurityScheme trong SpringDoc
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter JWT token in format: Bearer <token>',
        },
      },
    },
    // Áp dụng security scheme này cho toàn bộ các API (có thể override ở từng API)
    security: [
      {
        BearerAuth: [],
      },
    ],
  },
  // Đường dẫn đến các file chứa JSDoc comments cho API
  apis: ['./src/modules/**/*.ts'],
};

export const swagger_specs = swaggerJsdoc(options);
