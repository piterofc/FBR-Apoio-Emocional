export const env = {
    DATABASE_URL: process.env.DATABASE_URL || '',
    JWT_SECRET: process.env.JWT_SECRET || '',
    RABBITMQ_URL: process.env.RABBITMQ_URL || 'amqp://rabbit:rabbit@localhost:5672',
};

if (!env.DATABASE_URL) {
    console.warn('Warning: DATABASE_URL is not set. Please set it in your environment variables.');
}

if (!env.JWT_SECRET) {
    console.warn('Warning: JWT_SECRET is not set. Please set it in your environment variables.');
}

if (!env.RABBITMQ_URL) {
    console.warn('Warning: RABBITMQ_URL is not set. Please set it in your environment variables.');
}