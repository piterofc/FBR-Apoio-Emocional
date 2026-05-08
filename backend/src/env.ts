export const env = {
    DATABASE_URL: process.env.DATABASE_URL || '',
    JWT_SECRET: process.env.JWT_SECRET || '',
};

if (!env.DATABASE_URL) {
    console.warn('Warning: DATABASE_URL is not set. Please set it in your environment variables.');
}

if (!env.JWT_SECRET) {
    console.warn('Warning: JWT_SECRET is not set. Please set it in your environment variables.');
}